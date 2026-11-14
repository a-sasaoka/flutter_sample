// ignore_for_file: document_ignores

import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/core/network/request_auth_pin.dart';
import 'package:flutter_sample/src/features/auth/data/token_interceptor.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:legacy_checks/legacy_checks.dart';
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

class FakeResponse<T> extends Fake implements Response<T> {}

void main() {
  late MockTokenStorage mockStorage;
  late MockDio mockBaseDio;
  late MockTokenRefreshCallback mockRefreshToken;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeDioException());
    registerFallbackValue(FakeResponse<dynamic>());
  });

  setUp(() {
    mockStorage = MockTokenStorage();
    mockBaseDio = MockDio();
    mockRefreshToken = MockTokenRefreshCallback();

    container = ProviderContainer(
      overrides: [
        tokenStorageInternalProvider.overrideWithValue(mockStorage),
        baseDioProvider.overrideWithValue(mockBaseDio),
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

      // 内部で await されるため、dynamic で受けて await する
      await (interceptor as dynamic).onRequest(options, handler);

      check(options.headers['Authorization']).equals('Bearer valid_token');
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

      final mockResponse = Response<dynamic>(
        requestOptions: options,
        data: {'success': true},
        statusCode: 200,
      );

      when(
        () => mockBaseDio.fetch<dynamic>(any()),
      ).thenAnswer((_) async => mockResponse);

      await (interceptor as dynamic).onError(error401, handler);

      check(options.headers['Authorization']).equals('Bearer new_token');
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

      await (interceptor as dynamic).onError(error401, handler);

      verify(() => handler.next(error401)).called(1);
      verifyNever(() => mockBaseDio.fetch<dynamic>(any()));
    });

    test('onError: リフレッシュ処理中に例外が発生した場合、安全に false を返し元のエラーを流すこと', () async {
      final interceptor = container.read(tokenInterceptorProvider);
      final handler = MockErrorInterceptorHandler();
      final error401 = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 401),
      );

      // リフレッシュ処理で例外を投げるように設定
      when(
        () => mockRefreshToken.call(),
      ).thenThrow(Exception('Network unstable'));

      await (interceptor as dynamic).onError(error401, handler);

      // 例外がキャッチされ、handler.next(error401) が呼ばれていることを確認
      verify(() => handler.next(error401)).called(1);
      verifyNever(() => mockBaseDio.fetch<dynamic>(any()));
    });

    test('二重リフレッシュ防止: 同時に 401 が発生しても、リフレッシュ関数は1回しか呼ばれないこと', () async {
      final interceptor = container.read(tokenInterceptorProvider);
      final handler1 = MockErrorInterceptorHandler();
      final handler2 = MockErrorInterceptorHandler();
      final options = RequestOptions(path: '/test');
      final error401 = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
      );

      // 1回目の呼び出しで少し待たせるように設定
      when(() => mockRefreshToken.call()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return true;
      });
      when(
        () => mockStorage.getAccessToken(),
      ).thenAnswer((_) async => 'new_token');
      when(() => mockBaseDio.fetch<dynamic>(any())).thenAnswer(
        (_) async => Response(requestOptions: options, statusCode: 200),
      );

      // 同時に2つのエラー処理を開始
      await Future.wait<void>([
        (interceptor as dynamic).onError(error401, handler1) as Future<void>,
        (interceptor as dynamic).onError(error401, handler2) as Future<void>,
      ]);

      // リフレッシュ関数は「1回だけ」しか呼ばれていないことを検証
      verify(() => mockRefreshToken.call()).called(1);
      verify(() => handler1.resolve(any())).called(1);
      verify(() => handler2.resolve(any())).called(1);
    });
  });

  test('onRequest: トークンがnullの場合、ヘッダーが付与されずnextが呼ばれること', () async {
    when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);

    final interceptor = container.read(tokenInterceptorProvider);
    final handler = MockRequestInterceptorHandler();
    final options = RequestOptions(path: '/test');

    await (interceptor as dynamic).onRequest(options, handler);

    check(options.headers.containsKey('Authorization')).equals(false);
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

    await (interceptor as dynamic).onError(error500, handler);

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
    when(() => mockBaseDio.fetch<dynamic>(any())).thenThrow(retryError);

    await (interceptor as dynamic).onError(error401, handler);

    verify(() => handler.next(retryError)).called(1);
  });

  test(
    'tokenRefreshCallbackProvider: オーバーライドされていない場合は UnimplementedError を投げること',
    () {
      final emptyContainer = ProviderContainer();

      // Riverpodは内部のエラーを ProviderException で包んで投げる仕様があるため、
      // エラーの文字列表現 (toString) の中に目的のメッセージが含まれているかを検証します。
      check(
        () => emptyContainer.read(tokenRefreshCallbackProvider),
      ).legacyMatcher(
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

  group('RequestAuthPin による送信元ユーザー固定', () {
    test(
      'onRequest: 認証情報取得前に別ユーザーへ切り替わった場合、getAccessTokenを呼ばずキャンセルとして拒否すること',
      () async {
        when(() => mockStorage.getUserId()).thenAnswer((_) async => 'user-b');
        final interceptor = container.read(tokenInterceptorProvider);
        final handler = MockRequestInterceptorHandler();
        final authPin = RequestAuthPin(expectedUserId: 'user-a');
        final options = RequestOptions(
          path: '/memos/memo-1',
          extra: {RequestAuthPin.extraKey: authPin},
        );

        await (interceptor as dynamic).onRequest(options, handler);

        verifyNever(() => mockStorage.getAccessToken());
        verifyNever(() => handler.next(any()));
        final captured = verify(() => handler.reject(captureAny())).captured;
        check(captured.length).equals(1);
        final rejected = captured.single as DioException;
        check(rejected.type).equals(DioExceptionType.cancel);
        check(options.headers.containsKey('Authorization')).isFalse();
        check(authPin.authorizationHeader).isNull();
      },
    );

    test(
      'onRequest: getAccessToken待機中に別ユーザーへ切り替わった場合、Authorizationを設定せず拒否すること',
      () async {
        var currentUserId = 'user-a';
        when(
          () => mockStorage.getUserId(),
        ).thenAnswer((_) async => currentUserId);
        when(() => mockStorage.getAccessToken()).thenAnswer((_) async {
          // getAccessToken 完了前に別ユーザーへ切り替わった状況を再現
          currentUserId = 'user-b';
          return 'token-b';
        });

        final interceptor = container.read(tokenInterceptorProvider);
        final handler = MockRequestInterceptorHandler();
        final authPin = RequestAuthPin(expectedUserId: 'user-a');
        final options = RequestOptions(
          path: '/memos/memo-1',
          extra: {RequestAuthPin.extraKey: authPin},
        );

        await (interceptor as dynamic).onRequest(options, handler);

        verifyNever(() => handler.next(any()));
        final captured = verify(() => handler.reject(captureAny())).captured;
        check(
          (captured.single as DioException).type,
        ).equals(DioExceptionType.cancel);
        check(options.headers.containsKey('Authorization')).isFalse();
        check(authPin.authorizationHeader).isNull();
      },
    );

    test('onRequest: expectedUserId 一致時にアクセストークンが null の場合は拒否すること', () async {
      when(() => mockStorage.getUserId()).thenAnswer((_) async => 'user-a');
      when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);

      final interceptor = container.read(tokenInterceptorProvider);
      final handler = MockRequestInterceptorHandler();
      final options = RequestOptions(
        path: '/memos/memo-1',
        extra: {
          RequestAuthPin.extraKey: RequestAuthPin(expectedUserId: 'user-a'),
        },
      );

      await (interceptor as dynamic).onRequest(options, handler);

      verifyNever(() => handler.next(any()));
      final captured = verify(() => handler.reject(captureAny())).captured;
      check(
        (captured.single as DioException).type,
      ).equals(DioExceptionType.cancel);
    });

    test('onRequest: JWT内のsubがexpectedUserIdと異なる場合は拒否すること', () async {
      // sub = user-b のJWT
      const jwtForUserB =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiJ1c2VyLWIifQ.'
          'signature';
      when(() => mockStorage.getUserId()).thenAnswer((_) async => 'user-a');
      when(
        () => mockStorage.getAccessToken(),
      ).thenAnswer((_) async => jwtForUserB);

      final interceptor = container.read(tokenInterceptorProvider);
      final handler = MockRequestInterceptorHandler();
      final options = RequestOptions(
        path: '/memos/memo-1',
        extra: {
          RequestAuthPin.extraKey: RequestAuthPin(expectedUserId: 'user-a'),
        },
      );

      await (interceptor as dynamic).onRequest(options, handler);

      verifyNever(() => handler.next(any()));
      verify(() => handler.reject(any())).called(1);
      check(options.headers.containsKey('Authorization')).isFalse();
    });

    test(
      'onRequest: 既にauthorizationHeaderが固定済みの場合はストレージを再参照せず維持すること',
      () async {
        when(() => mockStorage.getUserId()).thenAnswer((_) async => 'user-b');
        when(
          () => mockStorage.getAccessToken(),
        ).thenAnswer((_) async => 'token-b');

        final interceptor = container.read(tokenInterceptorProvider);
        final handler = MockRequestInterceptorHandler();
        final authPin = RequestAuthPin(expectedUserId: 'user-a')
          ..authorizationHeader = 'Bearer token-a';
        final options = RequestOptions(
          path: '/memos',
          extra: {RequestAuthPin.extraKey: authPin},
        );

        await (interceptor as dynamic).onRequest(options, handler);

        verifyNever(() => mockStorage.getUserId());
        verifyNever(() => mockStorage.getAccessToken());
        check(options.headers['Authorization']).equals('Bearer token-a');
        verify(() => handler.next(options)).called(1);
      },
    );

    test(
      'onError: 401リフレッシュ前に別ユーザーへ切り替わっていた場合はリフレッシュも再試行も行わずエラーを流すこと',
      () async {
        when(() => mockStorage.getUserId()).thenAnswer((_) async => 'user-b');
        final interceptor = container.read(tokenInterceptorProvider);
        final handler = MockErrorInterceptorHandler();
        final authPin = RequestAuthPin(expectedUserId: 'user-a')
          ..authorizationHeader = 'Bearer expired-token-a';
        final options = RequestOptions(
          path: '/memos/memo-1',
          headers: {'Authorization': 'Bearer expired-token-a'},
          extra: {RequestAuthPin.extraKey: authPin},
        );
        final error401 = DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 401),
        );

        await (interceptor as dynamic).onError(error401, handler);

        verifyNever(() => mockRefreshToken.call());
        verifyNever(() => mockStorage.getAccessToken());
        verifyNever(() => mockBaseDio.fetch<dynamic>(any()));
        check(
          options.headers['Authorization'],
        ).equals('Bearer expired-token-a');
        verify(() => handler.next(error401)).called(1);
      },
    );

    test(
      'onError: 401リフレッシュ実行中に別ユーザーへ切り替わった場合は別ユーザーのトークンへ書き換えず再試行しないこと',
      () async {
        var currentUserId = 'user-a';
        var currentToken = 'expired-token-a';
        when(
          () => mockStorage.getUserId(),
        ).thenAnswer((_) async => currentUserId);
        when(
          () => mockStorage.getAccessToken(),
        ).thenAnswer((_) async => currentToken);
        when(() => mockRefreshToken.call()).thenAnswer((_) async {
          // リフレッシュ中にアカウントBへ切り替わる
          currentUserId = 'user-b';
          currentToken = 'token-b';
          return true;
        });

        final interceptor = container.read(tokenInterceptorProvider);
        final handler = MockErrorInterceptorHandler();
        final authPin = RequestAuthPin(expectedUserId: 'user-a')
          ..authorizationHeader = 'Bearer expired-token-a';
        final options = RequestOptions(
          path: '/memos/memo-1',
          headers: {'Authorization': 'Bearer expired-token-a'},
          extra: {RequestAuthPin.extraKey: authPin},
        );
        final error401 = DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 401),
        );

        await (interceptor as dynamic).onError(error401, handler);

        verify(() => mockRefreshToken.call()).called(1);
        verifyNever(() => mockBaseDio.fetch<dynamic>(any()));
        check(
          options.headers['Authorization'],
        ).equals('Bearer expired-token-a');
        check(authPin.authorizationHeader).equals('Bearer expired-token-a');
        verify(() => handler.next(error401)).called(1);
      },
    );

    test('onError: 401リフレッシュ中も同一ユーザーのままであれば新トークンを固定更新して再試行すること', () async {
      when(() => mockStorage.getUserId()).thenAnswer((_) async => 'user-a');
      when(() => mockRefreshToken.call()).thenAnswer((_) async => true);
      when(
        () => mockStorage.getAccessToken(),
      ).thenAnswer((_) async => 'new-token-a');

      final interceptor = container.read(tokenInterceptorProvider);
      final handler = MockErrorInterceptorHandler();
      final authPin = RequestAuthPin(expectedUserId: 'user-a')
        ..authorizationHeader = 'Bearer expired-token-a';
      final options = RequestOptions(
        path: '/memos/memo-1',
        headers: {'Authorization': 'Bearer expired-token-a'},
        extra: {RequestAuthPin.extraKey: authPin},
      );
      final error401 = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
      );
      final mockResponse = Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
      );
      when(
        () => mockBaseDio.fetch<dynamic>(any()),
      ).thenAnswer((_) async => mockResponse);

      await (interceptor as dynamic).onError(error401, handler);

      check(options.headers['Authorization']).equals('Bearer new-token-a');
      check(authPin.authorizationHeader).equals('Bearer new-token-a');
      verify(() => mockBaseDio.fetch<dynamic>(options)).called(1);
      verify(() => handler.resolve(mockResponse)).called(1);
    });
  });
}
