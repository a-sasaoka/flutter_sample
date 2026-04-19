import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/network/dio_interceptor.dart';
import 'package:flutter_sample/src/core/network/logger_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

// モッククラス
class MockLogger extends Mock implements Logger {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockResponseInterceptorHandler extends Mock
    implements ResponseInterceptorHandler {}

// Fakeクラスを定義
class FakeDioException extends Fake implements DioException {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeResponse extends Fake implements Response<dynamic> {}

void main() {
  // setUpAll でフォールバック値を登録
  setUpAll(() {
    registerFallbackValue(FakeDioException());
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeResponse());
  });

  late MockLogger mockLogger;
  late ProviderContainer container;

  setUp(() {
    mockLogger = MockLogger();
    container = ProviderContainer(
      overrides: [
        loggerProvider.overrideWithValue(mockLogger),
      ],
    );
  });
  tearDown(() {
    container.dispose();
  });

  group('DioInterceptor テスト', () {
    test('onError: タイムアウト系エラーが TimeoutException に変換されること', () {
      // Arrange
      final interceptor = container.read(dioInterceptorProvider);
      final handler = MockErrorInterceptorHandler();
      final dioException = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionTimeout,
        message: 'timeout error',
      );

      // Act
      interceptor.onError(dioException, handler);

      // Assert
      // handler.reject が呼ばれ、その中の error が TimeoutException であることを検証
      final captured =
          verify(() => handler.reject(captureAny())).captured.first
              as DioException;
      expect(captured.error, isA<TimeoutException>());
    });

    test(
      'onError: badResponse(404) が NetworkException(statusCode: 404) に変換されること',
      () {
        // Arrange
        final interceptor = container.read(dioInterceptorProvider);
        final handler = MockErrorInterceptorHandler();
        final dioException = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 404,
          ),
        );

        // Act
        interceptor.onError(dioException, handler);

        // Assert
        final captured =
            verify(() => handler.reject(captureAny())).captured.first
                as DioException;
        expect(captured.error, isA<NetworkException>());
        final appEx = captured.error! as NetworkException;
        expect(appEx.statusCode, equals(404));
      },
    );

    test('onError: unknownエラーが UnknownException に変換されること', () {
      // Arrange
      final interceptor = container.read(dioInterceptorProvider);
      final handler = MockErrorInterceptorHandler();
      final dioException = DioException(
        requestOptions: RequestOptions(),
        message: 'unknown error',
      );

      // Act
      interceptor.onError(dioException, handler);

      // Assert
      final captured =
          verify(() => handler.reject(captureAny())).captured.first
              as DioException;
      expect(captured.error, isA<UnknownException>());
      expect(
        (captured.error! as UnknownException).message,
        contains('unknown error'),
      );
    });

    test('onRequest/onResponse: ログが出力され、handler.next が呼ばれること', () {
      // Arrange
      final interceptor = container.read(dioInterceptorProvider);
      final reqHandler = MockRequestInterceptorHandler();
      final resHandler = MockResponseInterceptorHandler();

      final options = RequestOptions(path: '/test');
      final response = Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
      );

      // Act & Assert (Request)
      interceptor.onRequest(options, reqHandler);
      verify(() => mockLogger.i(any<dynamic>())).called(1);
      verify(() => reqHandler.next(options)).called(1);

      // Act & Assert (Response)
      interceptor.onResponse(response, resHandler);
      verify(() => mockLogger.d(any<dynamic>())).called(1);
      verify(() => resHandler.next(response)).called(1);
    });
  });
}
