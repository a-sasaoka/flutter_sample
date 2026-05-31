import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/network/dio_interceptor.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

// モッククラス
class MockTalker extends Mock implements Talker {}

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

  late MockTalker mockTalker;
  late ProviderContainer container;

  setUp(() {
    mockTalker = MockTalker();
    container = ProviderContainer(
      overrides: [
        loggerProvider.overrideWithValue(mockTalker),
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
      check(captured.error).isA<TimeoutException>();
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
        check(captured.error).isA<BadRequestException>();
        final appEx = captured.error! as AppException;
        check(appEx.statusCode).equals(404);
      },
    );

    test('onError: badResponse(401) が UnauthenticatedException に変換されること', () {
      // Arrange
      final interceptor = container.read(dioInterceptorProvider);
      final handler = MockErrorInterceptorHandler();
      final dioException = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 401,
        ),
      );

      // Act
      interceptor.onError(dioException, handler);

      // Assert
      final captured =
          verify(() => handler.reject(captureAny())).captured.first
              as DioException;
      check(captured.error).isA<UnauthenticatedException>();
    });

    test('onError: badResponse(500) が ServerException に変換されること', () {
      // Arrange
      final interceptor = container.read(dioInterceptorProvider);
      final handler = MockErrorInterceptorHandler();
      final dioException = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 500,
        ),
      );

      // Act
      interceptor.onError(dioException, handler);

      // Assert
      final captured =
          verify(() => handler.reject(captureAny())).captured.first
              as DioException;
      check(captured.error).isA<ServerException>();
    });

    test('onError: badResponse 且つ statusCode が null の場合は '
        'UnknownException になること', () {
      // Arrange
      final interceptor = container.read(dioInterceptorProvider);
      final handler = MockErrorInterceptorHandler();
      final dioException = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(),
        ),
      );

      // Act
      interceptor.onError(dioException, handler);

      // Assert
      final captured =
          verify(() => handler.reject(captureAny())).captured.first
              as DioException;
      check(captured.error).isA<UnknownException>();
    });

    test('onError: 未定義の statusCode の場合は UnknownException になること', () {
      // Arrange
      final interceptor = container.read(dioInterceptorProvider);
      final handler = MockErrorInterceptorHandler();
      final dioException = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 299, // 定義外
        ),
      );

      // Act
      interceptor.onError(dioException, handler);

      // Assert
      final captured =
          verify(() => handler.reject(captureAny())).captured.first
              as DioException;
      check(captured.error).isA<UnknownException>();
    });

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
      check(captured.error)
          .isA<UnknownException>()
          .has((e) => e.message, 'message')
          .isNotNull()
          .contains('unknown error');
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
      verify(() => mockTalker.info(any<dynamic>())).called(1);
      verify(() => reqHandler.next(options)).called(1);

      // Act & Assert (Response)
      interceptor.onResponse(response, resHandler);
      verify(() => mockTalker.debug(any<dynamic>())).called(1);
      verify(() => resHandler.next(response)).called(1);
    });
  });
}
