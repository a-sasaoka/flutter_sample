import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/core/network/retry_interceptor.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/uuid_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:uuid/uuid.dart';

class MockUuid extends Mock implements Uuid {}

class MockTalker extends Mock implements Talker {}

class MockDio extends Mock implements Dio {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeDioException extends Fake implements DioException {}

class FakeResponse<T> extends Fake implements Response<T> {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeDioException());
    registerFallbackValue(FakeResponse<dynamic>());
    registerFallbackValue(StackTrace.current);
  });

  group('retryInterceptorProvider テスト', () {
    test('ProviderContainer から正常に RetryInterceptor が生成・取得できること', () {
      final mockUuid = MockUuid();
      final mockTalker = MockTalker();
      final mockBaseDio = MockDio();

      final container = ProviderContainer(
        overrides: [
          uuidProvider.overrideWithValue(mockUuid),
          loggerProvider.overrideWithValue(mockTalker),
          baseDioProvider.overrideWithValue(mockBaseDio),
        ],
      );
      addTearDown(container.dispose);

      final interceptor = container.read(retryInterceptorProvider);
      check(interceptor).isA<RetryInterceptor>();
    });
  });

  group('RetryInterceptor onRequest テスト', () {
    late MockUuid mockUuid;
    late MockTalker mockTalker;
    late MockDio mockRetryDio;
    late RetryInterceptor interceptor;
    late MockRequestInterceptorHandler handler;

    setUp(() {
      mockUuid = MockUuid();
      mockTalker = MockTalker();
      mockRetryDio = MockDio();
      interceptor = RetryInterceptor(
        uuid: mockUuid,
        talker: mockTalker,
        retryDio: mockRetryDio,
        initialDelay: Duration.zero,
      );
      handler = MockRequestInterceptorHandler();
      when(() => mockUuid.v4()).thenReturn('test-uuid-1234');
    });

    test('POST リクエストで Idempotency-Key が未設定なら自動付与されること', () {
      final options = RequestOptions(path: '/checkout', method: 'POST');
      interceptor.onRequest(options, handler);

      check(
        options.headers[RetryInterceptor.idempotencyKeyHeader],
      ).equals('test-uuid-1234');
      verify(() => handler.next(options)).called(1);
    });

    test('PUT リクエストで Idempotency-Key が未設定なら自動付与されること', () {
      final options = RequestOptions(path: '/profile', method: 'PUT');
      interceptor.onRequest(options, handler);

      check(
        options.headers[RetryInterceptor.idempotencyKeyHeader],
      ).equals('test-uuid-1234');
      verify(() => handler.next(options)).called(1);
    });

    test('PATCH リクエストで Idempotency-Key が未設定なら自動付与されること', () {
      final options = RequestOptions(path: '/memo/1', method: 'PATCH');
      interceptor.onRequest(options, handler);

      check(
        options.headers[RetryInterceptor.idempotencyKeyHeader],
      ).equals('test-uuid-1234');
      verify(() => handler.next(options)).called(1);
    });

    test('すでに Idempotency-Key がヘッダーに存在する場合は上書きされないこと', () {
      final options = RequestOptions(
        path: '/checkout',
        method: 'POST',
        headers: {RetryInterceptor.idempotencyKeyHeader: 'existing-key-5678'},
      );
      interceptor.onRequest(options, handler);

      check(
        options.headers[RetryInterceptor.idempotencyKeyHeader],
      ).equals('existing-key-5678');
      verifyNever(() => mockUuid.v4());
      verify(() => handler.next(options)).called(1);
    });

    test('GET リクエストには Idempotency-Key が付与されないこと', () {
      final options = RequestOptions(path: '/feed', method: 'GET');
      interceptor.onRequest(options, handler);

      check(
        options.headers.containsKey(RetryInterceptor.idempotencyKeyHeader),
      ).isFalse();
      verifyNever(() => mockUuid.v4());
      verify(() => handler.next(options)).called(1);
    });

    test('DELETE リクエストには Idempotency-Key が付与されないこと', () {
      final options = RequestOptions(path: '/memo/1', method: 'DELETE');
      interceptor.onRequest(options, handler);

      check(
        options.headers.containsKey(RetryInterceptor.idempotencyKeyHeader),
      ).isFalse();
      verifyNever(() => mockUuid.v4());
      verify(() => handler.next(options)).called(1);
    });
  });

  group('RetryInterceptor onError リトライテスト', () {
    late MockUuid mockUuid;
    late MockTalker mockTalker;
    late MockDio mockRetryDio;
    late RetryInterceptor interceptor;
    late MockErrorInterceptorHandler handler;

    setUp(() {
      mockUuid = MockUuid();
      mockTalker = MockTalker();
      mockRetryDio = MockDio();
      interceptor = RetryInterceptor(
        uuid: mockUuid,
        talker: mockTalker,
        retryDio: mockRetryDio,
        initialDelay: Duration.zero, // テスト高速化
      );
      handler = MockErrorInterceptorHandler();
    });

    test('GET 通信で connectionTimeout 発生時、リトライが走り成功レスポンスが解決されること', () async {
      final options = RequestOptions(path: '/feed', method: 'GET');
      final error = DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      );
      final successResponse = Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: {'status': 'ok'},
      );

      when(
        () => mockRetryDio.fetch<dynamic>(any()),
      ).thenAnswer((_) async => successResponse);

      await interceptor.onError(error, handler);

      verify(() => mockRetryDio.fetch<dynamic>(any())).called(1);
      verify(() => handler.resolve(successResponse)).called(1);
      verifyNever(() => handler.next(any()));
      verify(() => mockTalker.warning(any<String>())).called(1);
      verify(() => mockTalker.info(any<String>())).called(1);
    });

    test(
      'initialDelay > Duration.zero の場合、Future.delayed の待機処理が実行されること',
      () async {
        final delayInterceptor = RetryInterceptor(
          uuid: mockUuid,
          talker: mockTalker,
          retryDio: mockRetryDio,
          maxRetries: 1, // デフォルトのinitialDelay（1秒遅延）を検証
        );
        final options = RequestOptions(path: '/feed', method: 'GET');
        final error = DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
        final successResponse = Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
        );

        when(
          () => mockRetryDio.fetch<dynamic>(any()),
        ).thenAnswer((_) async => successResponse);

        await delayInterceptor.onError(error, handler);

        verify(() => mockRetryDio.fetch<dynamic>(any())).called(1);
        verify(() => handler.resolve(successResponse)).called(1);
      },
    );

    test('POST 通信で connectionError 発生時、同一の Idempotency-Key で再送されること', () async {
      final options = RequestOptions(
        path: '/order',
        method: 'POST',
        headers: {RetryInterceptor.idempotencyKeyHeader: 'order-key-999'},
      );
      final error = DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
      final successResponse = Response<dynamic>(
        requestOptions: options,
        statusCode: 201,
        data: {'orderId': 123},
      );

      when(
        () => mockRetryDio.fetch<dynamic>(any()),
      ).thenAnswer((_) async => successResponse);

      await interceptor.onError(error, handler);

      verify(
        () => mockRetryDio.fetch<dynamic>(
          any(
            that: isA<RequestOptions>().having(
              (o) => o.headers[RetryInterceptor.idempotencyKeyHeader],
              'idempotencyKey',
              'order-key-999',
            ),
          ),
        ),
      ).called(1);
      verify(() => handler.resolve(successResponse)).called(1);
    });

    test('sendTimeout 発生時にリトライが走ること', () async {
      final options = RequestOptions(path: '/data', method: 'GET');
      final successResponse = Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
      );
      when(
        () => mockRetryDio.fetch<dynamic>(any()),
      ).thenAnswer((_) async => successResponse);

      final sendTimeoutError = DioException(
        requestOptions: options,
        type: DioExceptionType.sendTimeout,
      );
      await interceptor.onError(sendTimeoutError, handler);
      verify(() => handler.resolve(successResponse)).called(1);
    });

    test('receiveTimeout 発生時にリトライが走ること', () async {
      final options = RequestOptions(path: '/data', method: 'GET');
      final successResponse = Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
      );
      when(
        () => mockRetryDio.fetch<dynamic>(any()),
      ).thenAnswer((_) async => successResponse);

      final receiveTimeoutError = DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      );
      await interceptor.onError(receiveTimeoutError, handler);
      verify(() => handler.resolve(successResponse)).called(1);
    });

    test('502, 503, 504 のサーバー一時エラー時にもリトライが走ること', () async {
      final options = RequestOptions(path: '/api', method: 'GET');
      final successResponse = Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
      );
      when(
        () => mockRetryDio.fetch<dynamic>(any()),
      ).thenAnswer((_) async => successResponse);

      for (final statusCode in [502, 503, 504]) {
        final serverError = DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: statusCode),
        );
        await interceptor.onError(serverError, handler);
      }

      verify(() => handler.resolve(successResponse)).called(3);
    });

    test('400 Bad Request 等のクライアントエラー時はリトライせず即時次へ流すこと', () async {
      final options = RequestOptions(path: '/api', method: 'GET');
      final badRequestError = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: options, statusCode: 400),
      );

      await interceptor.onError(badRequestError, handler);

      verifyNever(() => mockRetryDio.fetch<dynamic>(any()));
      verify(() => handler.next(badRequestError)).called(1);
    });

    test('500 Internal Server Error など 502/503/504 以外のエラーはリトライしないこと', () async {
      final options = RequestOptions(path: '/api', method: 'GET');
      final internalError = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: options, statusCode: 500),
      );

      await interceptor.onError(internalError, handler);

      verifyNever(() => mockRetryDio.fetch<dynamic>(any()));
      verify(() => handler.next(internalError)).called(1);
    });

    test('cancel エラー時はリトライしないこと', () async {
      final options = RequestOptions(path: '/api', method: 'GET');
      final cancelError = DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
      );

      await interceptor.onError(cancelError, handler);

      verifyNever(() => mockRetryDio.fetch<dynamic>(any()));
      verify(() => handler.next(cancelError)).called(1);
    });

    test('最大リトライ回数（3回）を超えた場合、最後のエラーが handler.next に流れること', () async {
      final options = RequestOptions(path: '/api', method: 'GET');
      final error = DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      );

      // fetch が常にエラーを返すようにする
      when(() => mockRetryDio.fetch<dynamic>(any())).thenThrow(error);

      await interceptor.onError(error, handler);

      // 3回 fetch が試行され、最後は handler.next が呼ばれる
      verify(() => mockRetryDio.fetch<dynamic>(any())).called(3);
      verify(() => handler.next(error)).called(1);
      verifyNever(() => handler.resolve(any()));
      // 接続タイムアウト時：3回のリトライ試行時は warning、最後は handle が呼ばれること
      verify(() => mockTalker.warning(any<String>())).called(3); // 3回リトライ試行
      verify(
        () => mockTalker.handle(error, any<StackTrace>(), any<String>()),
      ).called(1);
    });

    test(
      '503 等のサーバー障害で最大リトライ回数を超えた場合、talker.handle で Crashlytics 送信されること',
      () async {
        final options = RequestOptions(path: '/api', method: 'GET');
        final serverError = DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 503),
        );

        // fetch が常に 503 エラーを返すようにする
        when(() => mockRetryDio.fetch<dynamic>(any())).thenThrow(serverError);

        await interceptor.onError(serverError, handler);

        // 3回再送試行後、諦めて talker.handle が呼ばれること
        verify(() => mockRetryDio.fetch<dynamic>(any())).called(3);
        verify(() => handler.next(serverError)).called(1);
        verify(
          () =>
              mockTalker.handle(serverError, any<StackTrace>(), any<String>()),
        ).called(1);
      },
    );

    test('再送処理（fetch）中に予期せぬ例外が発生した場合、talker.handle で送信され安全に終了すること', () async {
      final options = RequestOptions(path: '/api', method: 'GET');
      final error = DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      );
      final unexpectedException = StateError(
        'Unexpected memory or system error',
      );

      // fetch が DioException 以外の例外をスローするように設定
      when(
        () => mockRetryDio.fetch<dynamic>(any()),
      ).thenThrow(unexpectedException);

      await interceptor.onError(error, handler);

      // 予期せぬ例外が talker.handle でキャッチされ、handler.next に元のエラーが渡されること
      verify(() => mockRetryDio.fetch<dynamic>(any())).called(1);
      verify(
        () => mockTalker.handle(
          unexpectedException,
          any<StackTrace>(),
          any<String>(),
        ),
      ).called(1);
      verify(() => handler.next(error)).called(1);
      verifyNever(() => handler.resolve(any()));
    });

    test('Stream リクエストボディの場合はリトライせず即時次へ流すこと', () async {
      final options = RequestOptions(
        path: '/upload',
        method: 'POST',
        data: const Stream<List<int>>.empty(),
      );
      final streamError = DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );

      await interceptor.onError(streamError, handler);

      verifyNever(() => mockRetryDio.fetch<dynamic>(any()));
      verify(() => handler.next(streamError)).called(1);
    });

    test('FormData リクエストボディの場合、FormData.clone() で複製されて再送されること', () async {
      final formData = FormData.fromMap({'key': 'value'});
      final options = RequestOptions(
        path: '/upload',
        method: 'POST',
        data: formData,
      );
      final error = DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      );
      final successResponse = Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: {'status': 'uploaded'},
      );

      when(
        () => mockRetryDio.fetch<dynamic>(any()),
      ).thenAnswer((_) async => successResponse);

      await interceptor.onError(error, handler);

      final captured =
          verify(
                () => mockRetryDio.fetch<dynamic>(captureAny()),
              ).captured.single
              as RequestOptions;

      check(captured.data).isA<FormData>();
      // 元のインスタンスとは別インスタンスにクローンされていること
      check(identical(captured.data, formData)).isFalse();
      final clonedFormData = captured.data! as FormData;
      check(clonedFormData.fields.first.value).equals('value');
      verify(() => handler.resolve(successResponse)).called(1);
    });
  });
}
