import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/src/core/network/token_interceptor.dart';
import 'package:flutter_sample/src/core/storage/token_storage.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// 💡 implements だけで定義 (extends は不要)
class MockTokenStorage extends Mock implements TokenStorage {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDio extends Mock implements Dio {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

// Fake 群
class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeDioException extends Fake implements DioException {}

class FakeResponse extends Fake implements Response<Map<String, dynamic>> {}

void main() {
  late MockTokenStorage mockStorage;
  late MockAuthRepository mockAuthRepo;
  late MockDio mockRetryDio;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeDioException());
    registerFallbackValue(FakeResponse());
  });

  setUp(() {
    mockStorage = MockTokenStorage();
    mockAuthRepo = MockAuthRepository();
    mockRetryDio = MockDio();

    container = ProviderContainer(
      overrides: [
        // 🔥 重要：.notifier を付けず、InternalProvider を直接 overrideWithValue する
        // これにより、インターセプター内の ref.read(tokenStorageInternalProvider) が
        // 確実に mockStorage を返すようになります。
        tokenStorageInternalProvider.overrideWithValue(mockStorage),
        authRepositoryInternalProvider.overrideWithValue(mockAuthRepo),
        retryDioProvider.overrideWithValue(mockRetryDio),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('TokenInterceptor', () {
    test('onRequest: トークンがある場合、Authorizationヘッダーが付与されること', () async {
      // Arrange: ここで定義した mockStorage が InternalProvider を通じて
      // interceptor に注入されるようになります。
      when(
        () => mockStorage.getAccessToken(),
      ).thenAnswer((_) async => 'valid_token');

      final interceptor = container.read(tokenInterceptorProvider);
      final handler = MockRequestInterceptorHandler();
      final options = RequestOptions(path: '/test');

      // Act
      interceptor.onRequest(options, handler);

      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(options.headers['Authorization'], equals('Bearer valid_token'));
      verify(() => handler.next(options)).called(1);
    });

    test('onError: 401エラー時にトークンリフレッシュが成功すれば、リトライが行われること', () async {
      // Arrange
      final interceptor = container.read(tokenInterceptorProvider);
      final handler = MockErrorInterceptorHandler();
      final options = RequestOptions(path: '/test');
      final error401 = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
      );

      when(() => mockAuthRepo.refreshToken()).thenAnswer((_) async => true);
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

      // Act
      interceptor.onError(error401, handler);

      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(options.headers['Authorization'], equals('Bearer new_token'));
      verify(() => handler.resolve(mockResponse)).called(1);
    });

    test('onError: 401エラーだがリフレッシュに失敗した場合、そのままエラーを流すこと', () async {
      // Arrange
      final interceptor = container.read(tokenInterceptorProvider);
      final handler = MockErrorInterceptorHandler();
      final error401 = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 401),
      );

      when(() => mockAuthRepo.refreshToken()).thenAnswer((_) async => false);

      // Act
      interceptor.onError(error401, handler);

      await Future<void>.delayed(Duration.zero);

      // Assert
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

    verifyNever(() => mockAuthRepo.refreshToken());
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

    when(() => mockAuthRepo.refreshToken()).thenAnswer((_) async => true);
    when(
      () => mockStorage.getAccessToken(),
    ).thenAnswer((_) async => 'new_token');

    final retryError = DioException(
      requestOptions: options,
      error: 'Retry failed',
    );
    // fetchが呼ばれた時に例外を投げるように設定
    when(
      () => mockRetryDio.fetch<Map<String, dynamic>>(any()),
    ).thenThrow(retryError);

    interceptor.onError(error401, handler);
    await Future<void>.delayed(Duration.zero);

    verify(() => handler.next(retryError)).called(1);
  });
}
