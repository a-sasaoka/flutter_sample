// ignore_for_file: one_member_abstracts, document_ignores

import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/network/token_interceptor.dart';
import 'package:flutter_sample/src/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モッククラス群 ---

class MockTokenStorage extends Mock implements TokenStorage {}

class MockDio extends Mock implements Dio {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

// 関数をモック化するための抽象クラスを定義
abstract class _MockTokenRefreshCallable {
  Future<bool> call();
}

class MockTokenRefreshCallback extends Mock
    implements _MockTokenRefreshCallable {}

// --- Fake群 ---

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeDioException extends Fake implements DioException {}

class FakeResponse extends Fake implements Response<Map<String, dynamic>> {}

void main() {
  late MockTokenStorage mockStorage;
  late MockDio mockRetryDio;
  late MockTokenRefreshCallback mockRefreshToken;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeDioException());
    registerFallbackValue(FakeResponse());
  });

  setUp(() {
    mockStorage = MockTokenStorage();
    mockRetryDio = MockDio();
    mockRefreshToken = MockTokenRefreshCallback();

    container = ProviderContainer(
      overrides: [
        tokenStorageInternalProvider.overrideWithValue(mockStorage),
        retryDioProvider.overrideWithValue(mockRetryDio),
        tokenRefreshCallbackProvider.overrideWith(
          (ref) => mockRefreshToken.call,
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('TokenInterceptor', () {
    test('onRequest: トークンがある場合、Authorizationヘッダーが付与されること', () async {
      when(
        () => mockStorage.getAccessToken(),
      ).thenAnswer((_) async => 'valid_token');

      final interceptor = container.read(tokenInterceptorProvider);
      final handler = MockRequestInterceptorHandler();
      final options = RequestOptions(path: '/test');

      interceptor.onRequest(options, handler);
      await Future<void>.delayed(Duration.zero);

      expect(options.headers['Authorization'], equals('Bearer valid_token'));
      verify(() => handler.next(options)).called(1);
    });

    test('onError: 401エラー時にトークンリフレッシュが成功すれば、リトライが行われること', () async {
      final interceptor = container.read(tokenInterceptorProvider);
      final handler = MockErrorInterceptorHandler();
      final options = RequestOptions(path: '/test');
      final error401 = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
      );

      // モック関数の振る舞いを定義
      when(() => mockRefreshToken.call()).thenAnswer((_) async => true);

      when(
        () => mockStorage.getAccessToken(),
      ).thenAnswer((_) async => 'new_token');

      final mockResponse = Response<Map<String, dynamic>>(
        requestOptions: options,
        data: {'success': true},
        statusCode: 200,
      );

      when(
        () => mockRetryDio.fetch<Map<String, dynamic>>(any()),
      ).thenAnswer((_) async => mockResponse);

      interceptor.onError(error401, handler);
      await Future<void>.delayed(Duration.zero);

      expect(options.headers['Authorization'], equals('Bearer new_token'));
      verify(() => handler.resolve(mockResponse)).called(1);
    });

    test('onError: 401エラーだがリフレッシュに失敗した場合、そのままエラーを流すこと', () async {
      final interceptor = container.read(tokenInterceptorProvider);
      final handler = MockErrorInterceptorHandler();
      final error401 = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 401),
      );

      // モック関数が false を返すように設定
      when(() => mockRefreshToken.call()).thenAnswer((_) async => false);

      interceptor.onError(error401, handler);
      await Future<void>.delayed(Duration.zero);

      verify(() => handler.next(error401)).called(1);
      verifyNever(() => mockRetryDio.fetch<dynamic>(any()));
    });
  });

  test('onRequest: トークンがnullの場合、ヘッダーが付与されずnextが呼ばれること', () async {
    when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);

    final interceptor = container.read(tokenInterceptorProvider);
    final handler = MockRequestInterceptorHandler();
    final options = RequestOptions(path: '/test');

    interceptor.onRequest(options, handler);
    await Future<void>.delayed(Duration.zero);

    expect(options.headers.containsKey('Authorization'), isFalse);
    verify(() => handler.next(options)).called(1);
  });

  test('onError: 401以外のエラーの場合、リフレッシュせずにそのままエラーを流すこと', () async {
    final interceptor = container.read(tokenInterceptorProvider);
    final handler = MockErrorInterceptorHandler();
    final options = RequestOptions(path: '/test');
    final error500 = DioException(
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: 500),
    );

    interceptor.onError(error500, handler);
    await Future<void>.delayed(Duration.zero);

    // リフレッシュ関数が一度も呼ばれていないことを検証
    verifyNever(() => mockRefreshToken.call());
    verify(() => handler.next(error500)).called(1);
  });

  test('onError: 再リクエスト(retryDio)中にDioExceptionが発生した場合、そのエラーを流すこと', () async {
    final interceptor = container.read(tokenInterceptorProvider);
    final handler = MockErrorInterceptorHandler();
    final options = RequestOptions(path: '/test');
    final error401 = DioException(
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: 401),
    );

    when(() => mockRefreshToken.call()).thenAnswer((_) async => true);
    when(
      () => mockStorage.getAccessToken(),
    ).thenAnswer((_) async => 'new_token');

    final retryError = DioException(
      requestOptions: options,
      error: 'Retry failed',
    );
    when(
      () => mockRetryDio.fetch<Map<String, dynamic>>(any()),
    ).thenThrow(retryError);

    interceptor.onError(error401, handler);
    await Future<void>.delayed(Duration.zero);

    verify(() => handler.next(retryError)).called(1);
  });

  test(
    'tokenRefreshCallbackProvider: オーバーライドされていない場合は UnimplementedError を投げること',
    () {
      final emptyContainer = ProviderContainer();

      // Riverpodは内部のエラーを ProviderException で包んで投げる仕様があるため、
      // エラーの文字列表現 (toString) の中に目的のメッセージが含まれているかを検証します。
      expect(
        () => emptyContainer.read(tokenRefreshCallbackProvider),
        throwsA(
          predicate(
            (e) => e.toString().contains(
              'Please override it in the ProviderScope of the App layer',
            ),
          ),
        ),
      );

      emptyContainer.dispose();
    },
  );
}
