import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_sample/src/core/network/firebase_performance_dio_interceptor.dart';
import 'package:flutter_sample/src/core/performance/firebase_performance_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockFirebasePerformance extends Mock implements FirebasePerformance {}

class MockHttpMetric extends Mock implements HttpMetric {}

class MockTalker extends Mock implements Talker {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockResponseInterceptorHandler extends Mock
    implements ResponseInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(StackTrace.current);
    registerFallbackValue(HttpMethod.Get);
    registerFallbackValue(RequestOptions());
    registerFallbackValue(
      Response<dynamic>(requestOptions: RequestOptions()),
    );
    registerFallbackValue(
      DioException(requestOptions: RequestOptions()),
    );
  });

  late MockFirebasePerformance mockPerformance;
  late MockHttpMetric mockMetric;
  late MockTalker mockTalker;
  late FirebasePerformanceDioInterceptor interceptor;

  setUp(() {
    mockPerformance = MockFirebasePerformance();
    mockMetric = MockHttpMetric();
    mockTalker = MockTalker();

    when(
      () => mockPerformance.newHttpMetric(any(), any()),
    ).thenReturn(mockMetric);
    when(() => mockMetric.start()).thenAnswer((_) async {});
    when(() => mockMetric.stop()).thenAnswer((_) async {});
    when(() => mockTalker.debug(any<dynamic>())).thenReturn(null);
    when(
      () => mockTalker.handle(
        any<Object>(),
        any<StackTrace?>(),
        any<dynamic>(),
      ),
    ).thenReturn(null);

    interceptor = FirebasePerformanceDioInterceptor(
      performance: mockPerformance,
      talker: mockTalker,
    );
  });

  group('FirebasePerformanceDioInterceptor Tests', () {
    test('onRequest: GETリクエストでHttpMetricが作成・開始されextraに格納されること', () async {
      final options = RequestOptions(
        path: 'https://api.example.com/users',
        method: 'GET',
      );
      final handler = MockRequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      verify(
        () => mockPerformance.newHttpMetric(
          'https://api.example.com/users',
          HttpMethod.Get,
        ),
      ).called(1);
      verify(() => mockMetric.start()).called(1);
      check(options.extra['_firebase_performance_metric']).equals(mockMetric);
      verify(() => handler.next(options)).called(1);
    });

    test(
      'onRequest: 各種HTTPメソッドが正しく変換されること',
      () async {
        final methods = {
          'POST': HttpMethod.Post,
          'PUT': HttpMethod.Put,
          'DELETE': HttpMethod.Delete,
          'PATCH': HttpMethod.Patch,
          'HEAD': HttpMethod.Head,
          'OPTIONS': HttpMethod.Options,
          'TRACE': HttpMethod.Trace,
          'CONNECT': HttpMethod.Connect,
        };

        for (final entry in methods.entries) {
          final options = RequestOptions(
            path: 'https://api.example.com/test',
            method: entry.key,
          );
          final handler = MockRequestInterceptorHandler();

          await interceptor.onRequest(options, handler);

          verify(
            () => mockPerformance.newHttpMetric(
              'https://api.example.com/test',
              entry.value,
            ),
          ).called(1);
        }
      },
    );

    test(
      'onRequest: performance が null の場合は HttpMetric を作成せずにスキップすること',
      () async {
        final nullInterceptor = FirebasePerformanceDioInterceptor(
          performance: null,
          talker: mockTalker,
        );
        final options = RequestOptions(
          path: 'https://api.example.com/users',
          method: 'GET',
        );
        final handler = MockRequestInterceptorHandler();

        await nullInterceptor.onRequest(options, handler);

        verifyNever(() => mockPerformance.newHttpMetric(any(), any()));
        verify(() => handler.next(options)).called(1);
      },
    );

    test('onRequest: 未知のメソッドの場合はHttpMetricを作成せずにスキップすること', () async {
      final options = RequestOptions(
        path: 'https://api.example.com/test',
        method: 'CUSTOM_METHOD',
      );
      final handler = MockRequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      verifyNever(() => mockPerformance.newHttpMetric(any(), any()));
      verify(() => handler.next(options)).called(1);
    });

    test(
      'onRequest: data が List<int> / String の場合に requestPayloadSize が設定されること',
      () async {
        final byteOptions = RequestOptions(
          path: 'https://api.example.com/upload',
          method: 'POST',
          data: [1, 2, 3, 4],
        );
        final byteHandler = MockRequestInterceptorHandler();
        await interceptor.onRequest(byteOptions, byteHandler);
        verify(() => mockMetric.requestPayloadSize = 4).called(1);

        final stringOptions = RequestOptions(
          path: 'https://api.example.com/text',
          method: 'POST',
          data: 'hello',
        );
        final stringHandler = MockRequestInterceptorHandler();
        await interceptor.onRequest(stringOptions, stringHandler);
        verify(() => mockMetric.requestPayloadSize = 5).called(1);
      },
    );

    test(
      'onRequest: 例外発生時に talker.handle が呼ばれ、リクエストは handler.next で継続されること',
      () async {
        final exception = Exception('Metric creation failed');
        when(
          () => mockPerformance.newHttpMetric(any(), any()),
        ).thenThrow(exception);

        final options = RequestOptions(
          path: 'https://api.example.com/users',
          method: 'GET',
        );
        final handler = MockRequestInterceptorHandler();

        await interceptor.onRequest(options, handler);

        verify(
          () => mockTalker.handle(
            exception,
            any<StackTrace?>(),
            'Failed to start HttpMetric on request',
          ),
        ).called(1);
        verify(() => handler.next(options)).called(1);
      },
    );

    test(
      'onResponse: レスポンス情報が設定され metric.stop() が呼ばれること',
      () async {
        final options = RequestOptions(path: 'https://api.example.com/users')
          ..extra['_firebase_performance_metric'] = mockMetric;
        final response = Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          headers: Headers.fromMap({
            Headers.contentTypeHeader: ['application/json'],
          }),
          data: '{"status":"ok"}',
        );
        final handler = MockResponseInterceptorHandler();

        await interceptor.onResponse(response, handler);

        verify(() => mockMetric.httpResponseCode = 200).called(1);
        verify(
          () => mockMetric.responseContentType = 'application/json',
        ).called(1);
        verify(() => mockMetric.responsePayloadSize = 15).called(1);
        verify(() => mockMetric.stop()).called(1);
        verify(() => handler.next(response)).called(1);
      },
    );

    test(
      'onResponse: data が List<int> の場合にも responsePayloadSize が設定されること',
      () async {
        final options = RequestOptions(path: 'https://api.example.com/data')
          ..extra['_firebase_performance_metric'] = mockMetric;
        final response = Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: [10, 20, 30],
        );
        final handler = MockResponseInterceptorHandler();

        await interceptor.onResponse(response, handler);

        verify(() => mockMetric.responsePayloadSize = 3).called(1);
        verify(() => mockMetric.stop()).called(1);
      },
    );

    test(
      'onResponse: metric.stop() 時に例外が発生しても talker.handle が呼ばれレスポンスは継続すること',
      () async {
        final stopException = Exception('Stop failed');
        when(() => mockMetric.stop()).thenThrow(stopException);

        final options = RequestOptions(path: 'https://api.example.com/users')
          ..extra['_firebase_performance_metric'] = mockMetric;
        final response = Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
        );
        final handler = MockResponseInterceptorHandler();

        await interceptor.onResponse(response, handler);

        verify(
          () => mockTalker.handle(
            stopException,
            any<StackTrace?>(),
            'Failed to stop HttpMetric on response',
          ),
        ).called(1);
        verify(() => handler.next(response)).called(1);
      },
    );

    test('onError: エラーステータスコードが設定され metric.stop() が呼ばれること', () async {
      final options = RequestOptions(path: 'https://api.example.com/error')
        ..extra['_firebase_performance_metric'] = mockMetric;
      final err = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 500),
      );
      final handler = MockErrorInterceptorHandler();

      await interceptor.onError(err, handler);

      verify(() => mockMetric.httpResponseCode = 500).called(1);
      verify(() => mockMetric.stop()).called(1);
      verify(() => handler.next(err)).called(1);
    });

    test(
      'onError: metric.stop() 時に例外が発生しても talker.handle が呼ばれエラーは継続すること',
      () async {
        final stopException = Exception('Stop error failed');
        when(() => mockMetric.stop()).thenThrow(stopException);

        final options = RequestOptions(path: 'https://api.example.com/error')
          ..extra['_firebase_performance_metric'] = mockMetric;
        final err = DioException(requestOptions: options);
        final handler = MockErrorInterceptorHandler();

        await interceptor.onError(err, handler);

        verify(
          () => mockTalker.handle(
            stopException,
            any<StackTrace?>(),
            'Failed to stop HttpMetric on error',
          ),
        ).called(1);
        verify(() => handler.next(err)).called(1);
      },
    );
  });

  group('firebasePerformanceDioInterceptorProvider Tests', () {
    test('プロバイダーが FirebasePerformanceDioInterceptor インスタンスを提供すること', () {
      final container = ProviderContainer(
        overrides: [
          firebasePerformanceProvider.overrideWithValue(mockPerformance),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      final interceptor = container.read(
        firebasePerformanceDioInterceptorProvider,
      );
      check(interceptor).isA<FirebasePerformanceDioInterceptor>();
      check(interceptor.performance).equals(mockPerformance);
      check(interceptor.talker).equals(mockTalker);
    });
  });
}
