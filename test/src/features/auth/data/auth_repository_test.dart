import 'dart:async';

import 'package:checks/checks.dart';
import 'package:dio/dio.dart'; // Responseクラス用
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/auth_session_lock.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

// --- モックとFakeクラスの定義 ---

// ApiClientのモック
class MockApiClient extends Mock implements ApiClient {}

// Dioのモック
class MockDio extends Mock implements Dio {}

// DioのResponseのモック
class MockResponse extends Mock implements Response<Map<String, dynamic>> {}

// Talkerのモック
class MockTalker extends Mock implements Talker {}

// TokenStorageのモック
class FakeTokenStorage extends Mock implements TokenStorage {
  FakeTokenStorage({
    this.initialRefreshToken,
    this.currentUserId,
    this.onSaveTokens,
  }) : currentRefreshToken = initialRefreshToken;

  final String? initialRefreshToken;
  String? currentUserId;
  String? currentRefreshToken;
  Future<void> Function(String accessToken, String refreshToken)? onSaveTokens;
  int getUserIdCalls = 0;

  // 保存された値を検証するためのプロパティ
  String? savedAccessToken;
  String? savedRefreshToken;

  @override
  Future<String?> getUserId() async {
    getUserIdCalls++;
    return currentUserId;
  }

  @override
  Future<String?> getAccessToken() async => savedAccessToken;

  @override
  Future<String?> getRefreshToken() async => currentRefreshToken;

  @override
  Future<void> clear() async {
    currentUserId = null;
    currentRefreshToken = null;
    savedAccessToken = null;
    savedRefreshToken = null;
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    savedAccessToken = accessToken;
    savedRefreshToken = refreshToken;
    currentRefreshToken = refreshToken;
    await onSaveTokens?.call(accessToken, refreshToken);
  }
}

void main() {
  late MockApiClient mockApi;
  late MockTalker mockTalker;

  setUpAll(() {
    registerFallbackValue(const AppException.unknown());
    registerFallbackValue(StackTrace.current);
  });

  setUp(() {
    mockApi = MockApiClient();
    mockTalker = MockTalker();
    when(
      () =>
          mockTalker.handle(any<Object>(), any<StackTrace?>(), any<dynamic>()),
    ).thenReturn(null);
  });

  /// 依存関係を注入した ProviderContainer を作成するヘルパー
  ProviderContainer createContainer(FakeTokenStorage fakeStorage) {
    final container = ProviderContainer(
      overrides: [
        authApiClientProvider.overrideWithValue(mockApi),
        // 💡 修正: tokenStorageProvider は Notifier ではないので (ref) => の形でオーバーライドする
        tokenStorageProvider.overrideWith((ref) => fakeStorage),
        loggerProvider.overrideWithValue(mockTalker),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AuthRepository', () {
    test('login: APIを呼び出し、取得したトークンをTokenStorageに保存すること', () async {
      // Arrange
      final fakeStorage = FakeTokenStorage();
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      final mockResponse = MockResponse();
      // APIが返すダミーのレスポンスデータを設定
      when(() => mockResponse.data).thenReturn({
        'access_token': 'new_access_token',
        'refresh_token': 'new_refresh_token',
      });
      // postメソッドが呼ばれたらモックレスポンスを返す
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      // Act
      await repo.login('test@example.com', 'password123');

      // Assert
      // 1. APIが正しい引数で呼ばれたか
      // Mapの比較はそのまま書くとインスタンス違いで失敗するため、equals() を使用する
      verify(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(
            named: 'data',
            that: equals({
              'email': 'test@example.com',
              'password': 'password123',
            }),
          ),
        ),
      ).called(1);

      // 2. TokenStorageに正しい値が保存されたか
      check(fakeStorage.savedAccessToken).equals('new_access_token');
      check(fakeStorage.savedRefreshToken).equals('new_refresh_token');
    });

    test('login: APIレスポンスにトークンが含まれていない場合、Exceptionを投げること', () async {
      // Arrange
      final fakeStorage = FakeTokenStorage();
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      final mockResponse = MockResponse();
      // access_token が欠落している不正なレスポンスをシミュレート
      when(() => mockResponse.data).thenReturn({
        'refresh_token': 'new_refresh_token', // access_tokenがない
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      // Act & Assert
      try {
        await repo.login('test@example.com', 'password123');
        fail('Exception not thrown');
      } on Exception catch (e) {
        check(e).isA<AppException>();
      }

      // 例外が発生し、TokenStorageに保存処理が行われていないことを確認
      check(fakeStorage.savedAccessToken).isNull();

      // talker.handle が呼ばれてCrashlyticsに送信されることを確認
      verify(
        () => mockTalker.handle(
          any<AppException>(),
          any<StackTrace>(),
          'Failed to parse login response: Missing or invalid tokens',
        ),
      ).called(1);
    });

    group('refreshToken', () {
      test('TokenStorageにリフレッシュトークンがない場合、APIを呼ばずに false を返すこと', () async {
        // Arrange: 初期リフレッシュトークンを null に設定
        final fakeStorage = FakeTokenStorage();
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        // Act
        final result = await repo.refreshToken(null);

        // Assert
        check(result).equals(false);
        // APIが一切呼ばれていないことを確認
        verifyNever(
          () => mockApi.post<Map<String, dynamic>>(
            any(),
            data: any<dynamic>(named: 'data'),
          ),
        );
      });

      test('APIのレスポンスに access_token が含まれていない場合、保存せずに false を返すこと', () async {
        // Arrange
        final fakeStorage = FakeTokenStorage(
          initialRefreshToken: 'old_refresh',
        );
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        final mockResponse = MockResponse();
        // access_token が null (または存在しない) レスポンスをシミュレート
        when(() => mockResponse.data).thenReturn({'access_token': null});

        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repo.refreshToken(null);

        // Assert
        check(result).equals(false);
        // 保存処理が呼ばれていない（プロパティがnullのまま）ことを確認
        check(fakeStorage.savedAccessToken).isNull();
      });

      test('APIから新しいアクセストークンを取得できた場合、保存して true を返すこと', () async {
        // Arrange
        final fakeStorage = FakeTokenStorage(
          initialRefreshToken: 'valid_refresh',
          currentUserId: 'user-a',
        );
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        final mockResponse = MockResponse();
        when(
          () => mockResponse.data,
        ).thenReturn({'access_token': 'refreshed_access'});

        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repo.refreshToken('user-a');

        // Assert
        check(result).equals(true);

        // APIが正しいリフレッシュトークンを送信したか
        verify(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(
              named: 'data',
              that: equals({'refresh_token': 'valid_refresh'}),
            ),
          ),
        ).called(1);

        // 新しいアクセストークンと、既存のリフレッシュトークンが保存されたか
        check(fakeStorage.savedAccessToken).equals('refreshed_access');
        check(fakeStorage.savedRefreshToken).equals('valid_refresh');
      });

      test('通信開始前から別ユーザーへ切り替わっていた場合、APIを呼ばずに false を返すこと', () async {
        final fakeStorage = FakeTokenStorage(
          initialRefreshToken: 'refresh-b',
          currentUserId: 'user-b',
        );
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        final result = await repo.refreshToken('user-a');

        check(result).equals(false);
        verifyNever(
          () => mockApi.post<Map<String, dynamic>>(
            any(),
            data: any<dynamic>(named: 'data'),
          ),
        );
        check(fakeStorage.savedAccessToken).isNull();
      });

      test('リフレッシュ通信中にサインアウトされた場合、保存せず false を返すこと', () async {
        final fakeStorage = FakeTokenStorage(
          initialRefreshToken: 'refresh-a',
          currentUserId: 'user-a',
        );
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        final refreshStarted = Completer<void>();
        final refreshGate = Completer<Map<String, dynamic>>();
        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async {
          refreshStarted.complete();
          final response = MockResponse();
          final data = await refreshGate.future;
          when(() => response.data).thenReturn(data);
          return response;
        });

        final refreshFuture = repo.refreshToken('user-a');
        await refreshStarted.future;

        await container.read(authSessionLockProvider).synchronized(() async {
          fakeStorage
            ..currentUserId = null
            ..currentRefreshToken = null;
        });

        refreshGate.complete({'access_token': 'new_access_a'});
        final result = await refreshFuture;

        check(result).equals(false);
        check(fakeStorage.savedAccessToken).isNull();
      });

      test('リフレッシュ通信中に別ユーザーBがログインした場合、Bのトークンを上書きせず false を返すこと', () async {
        late FakeTokenStorage fakeStorage;
        fakeStorage = FakeTokenStorage(
          initialRefreshToken: 'refresh-a',
          currentUserId: 'user-a',
          onSaveTokens: (accessToken, _) async {
            if (accessToken == 'access-b') {
              fakeStorage.currentUserId = 'user-b';
            }
          },
        );
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        final refreshStarted = Completer<void>();
        final refreshGate = Completer<Map<String, dynamic>>();
        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async {
          refreshStarted.complete();
          final response = MockResponse();
          final data = await refreshGate.future;
          when(() => response.data).thenReturn(data);
          return response;
        });
        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/login',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async {
          final response = MockResponse();
          when(() => response.data).thenReturn({
            'access_token': 'access-b',
            'refresh_token': 'refresh-b',
          });
          return response;
        });

        final refreshFuture = repo.refreshToken('user-a');
        await refreshStarted.future;

        await repo.login('b@example.com', 'password-b');
        refreshGate.complete({'access_token': 'new_access_a'});

        check(await refreshFuture).equals(false);
        check(fakeStorage.savedAccessToken).equals('access-b');
        check(fakeStorage.savedRefreshToken).equals('refresh-b');
        check(fakeStorage.currentUserId).equals('user-b');
      });

      test('保存中にloginが同時実行されても、ロックで直列化されてトークンが混ざらないこと', () async {
        final aSaveStarted = Completer<void>();
        final aSaveGate = Completer<void>();
        final saveOrder = <String>[];

        late FakeTokenStorage fakeStorage;
        fakeStorage = FakeTokenStorage(
          initialRefreshToken: 'refresh-a',
          currentUserId: 'user-a',
          onSaveTokens: (accessToken, _) async {
            if (accessToken == 'new_access_a') {
              saveOrder.add('a:start');
              aSaveStarted.complete();
              await aSaveGate.future;
              saveOrder.add('a:end');
            } else if (accessToken == 'access-b') {
              saveOrder.add('b:start');
              fakeStorage.currentUserId = 'user-b';
              saveOrder.add('b:end');
            }
          },
        );
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async {
          final response = MockResponse();
          when(
            () => response.data,
          ).thenReturn({'access_token': 'new_access_a'});
          return response;
        });
        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/login',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async {
          final response = MockResponse();
          when(() => response.data).thenReturn({
            'access_token': 'access-b',
            'refresh_token': 'refresh-b',
          });
          return response;
        });

        final refreshFuture = repo.refreshToken('user-a');
        await aSaveStarted.future;

        final loginFuture = repo.login('b@example.com', 'password-b');
        await Future<void>.delayed(Duration.zero);

        // Aの保存が完了するまで、Bの保存は開始されないこと
        check(saveOrder).deepEquals(['a:start']);

        aSaveGate.complete();
        final refreshed = await refreshFuture;
        await loginFuture;

        check(refreshed).equals(true);
        check(saveOrder).deepEquals(['a:start', 'a:end', 'b:start', 'b:end']);
        check(fakeStorage.savedAccessToken).equals('access-b');
        check(fakeStorage.savedRefreshToken).equals('refresh-b');
        check(fakeStorage.currentUserId).equals('user-b');
      });

      test('loginのsaveTokens実行中にリフレッシュが応答しても、ロック待ち後のユーザー照合で中断すること', () async {
        final refreshStarted = Completer<void>();
        final refreshGate = Completer<Map<String, dynamic>>();
        final bSaveStarted = Completer<void>();
        final bSaveGate = Completer<void>();

        late FakeTokenStorage fakeStorage;
        fakeStorage = FakeTokenStorage(
          initialRefreshToken: 'refresh-a',
          currentUserId: 'user-a',
          onSaveTokens: (accessToken, _) async {
            if (accessToken == 'access-b') {
              // トークン保存途中でまだ customUserId 書き換え前の状態を再現
              bSaveStarted.complete();
              await bSaveGate.future;
              fakeStorage.currentUserId = 'user-b';
            }
          },
        );
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async {
          refreshStarted.complete();
          final response = MockResponse();
          final data = await refreshGate.future;
          when(() => response.data).thenReturn(data);
          return response;
        });
        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/login',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async {
          final response = MockResponse();
          when(() => response.data).thenReturn({
            'access_token': 'access-b',
            'refresh_token': 'refresh-b',
          });
          return response;
        });

        final refreshFuture = repo.refreshToken('user-a');
        var refreshCompleted = false;
        unawaited(refreshFuture.then((_) => refreshCompleted = true));
        await refreshStarted.future;

        final loginFuture = repo.login('b@example.com', 'password-b');
        await bSaveStarted.future;

        refreshGate.complete({'access_token': 'new_access_a'});
        await Future<void>.delayed(Duration.zero);

        // BのsaveTokensがロック解放するまで、リフレッシュ側のロック後チェックも完了しないこと
        check(refreshCompleted).equals(false);

        bSaveGate.complete();
        await loginFuture;
        final refreshed = await refreshFuture;

        check(refreshed).equals(false);
        check(fakeStorage.savedAccessToken).equals('access-b');
        check(fakeStorage.savedRefreshToken).equals('refresh-b');
        check(fakeStorage.currentUserId).equals('user-b');
      });

      test(
        'ID未取得(null)トークン同士でサインアウト後に別ユーザーBがログインした場合、Bのトークンを上書きせず false を返すこと',
        () async {
          final fakeStorage = FakeTokenStorage(
            initialRefreshToken: 'refresh-a',
          );
          final container = createContainer(fakeStorage);
          final repo = container.read(authRepositoryProvider);

          final refreshStarted = Completer<void>();
          final refreshGate = Completer<Map<String, dynamic>>();
          when(
            () => mockApi.post<Map<String, dynamic>>(
              '/auth/refresh',
              data: any<dynamic>(named: 'data'),
            ),
          ).thenAnswer((_) async {
            refreshStarted.complete();
            final response = MockResponse();
            final data = await refreshGate.future;
            when(() => response.data).thenReturn(data);
            return response;
          });
          when(
            () => mockApi.post<Map<String, dynamic>>(
              '/auth/login',
              data: any<dynamic>(named: 'data'),
            ),
          ).thenAnswer((_) async {
            final response = MockResponse();
            when(() => response.data).thenReturn({
              'access_token': 'opaque-access-b',
              'refresh_token': 'refresh-b',
            });
            return response;
          });

          final refreshFuture = repo.refreshToken(null);
          await refreshStarted.future;

          await container.read(authStateProvider.notifier).logout();
          await repo.login('b@example.com', 'password-b');

          refreshGate.complete({'access_token': 'new_opaque_access_a'});

          check(await refreshFuture).equals(false);
          check(fakeStorage.savedAccessToken).equals('opaque-access-b');
          check(fakeStorage.savedRefreshToken).equals('refresh-b');
          check(fakeStorage.currentUserId).isNull();
        },
      );

      test('同一ユーザーがサインアウト後に再ログインした場合、新旧セッションを区別し旧リフレッシュ結果を保存しないこと', () async {
        late FakeTokenStorage fakeStorage;
        fakeStorage = FakeTokenStorage(
          initialRefreshToken: 'refresh-a-old',
          currentUserId: 'user-a',
          onSaveTokens: (accessToken, _) async {
            if (accessToken == 'access-a-new') {
              fakeStorage.currentUserId = 'user-a';
            }
          },
        );
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        final refreshStarted = Completer<void>();
        final refreshGate = Completer<Map<String, dynamic>>();
        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async {
          refreshStarted.complete();
          final response = MockResponse();
          final data = await refreshGate.future;
          when(() => response.data).thenReturn(data);
          return response;
        });
        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/login',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async {
          final response = MockResponse();
          when(() => response.data).thenReturn({
            'access_token': 'access-a-new',
            // リフレッシュトークンが同一値であってもセッション世代で区別できることを検証
            'refresh_token': 'refresh-a-old',
          });
          return response;
        });

        final refreshFuture = repo.refreshToken('user-a');
        await refreshStarted.future;

        await container.read(authStateProvider.notifier).logout();
        await repo.login('a@example.com', 'password-a');

        refreshGate.complete({'access_token': 'stale_refreshed_access_a'});

        check(await refreshFuture).equals(false);
        check(fakeStorage.savedAccessToken).equals('access-a-new');
        check(fakeStorage.savedRefreshToken).equals('refresh-a-old');
        check(fakeStorage.currentUserId).equals('user-a');
      });

      test('セッション世代が変わらずリフレッシュトークンのみ別値に変化していた場合も、保存せず false を返すこと', () async {
        final fakeStorage = FakeTokenStorage(initialRefreshToken: 'refresh-a');
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        final refreshStarted = Completer<void>();
        final refreshGate = Completer<Map<String, dynamic>>();
        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async {
          refreshStarted.complete();
          final response = MockResponse();
          final data = await refreshGate.future;
          when(() => response.data).thenReturn(data);
          return response;
        });

        final refreshFuture = repo.refreshToken(null);
        await refreshStarted.future;

        await container.read(authSessionLockProvider).synchronized(() async {
          fakeStorage.currentRefreshToken = 'refresh-b';
        });

        refreshGate.complete({'access_token': 'new_access_a'});

        check(await refreshFuture).equals(false);
        check(fakeStorage.savedAccessToken).isNull();
      });

      test('sessionLockを省略して生成した場合でも、デフォルトロックでrefreshTokenを実行できること', () async {
        final fakeStorage = FakeTokenStorage(
          initialRefreshToken: 'valid_refresh',
          currentUserId: 'user-a',
        );
        final repo = AuthRepository(
          api: mockApi,
          tokenStorage: fakeStorage,
          talker: mockTalker,
        );
        final mockResponse = MockResponse();
        when(
          () => mockResponse.data,
        ).thenReturn({'access_token': 'refreshed_access'});
        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await repo.refreshToken('user-a');

        check(result).equals(true);
        check(fakeStorage.savedAccessToken).equals('refreshed_access');
      });
    });
  });

  group('authApiClientProvider', () {
    test('baseDioProvider を使用した ApiClient を提供すること', () {
      final mockDio = MockDio();
      final container = ProviderContainer(
        overrides: [baseDioProvider.overrideWithValue(mockDio)],
      );
      addTearDown(container.dispose);

      final apiClient = container.read(authApiClientProvider);

      check(apiClient).isA<DioApiClient>();
    });
  });

  group('authRepositoryProvider', () {
    test(
      '依存関係（APIクライアントとトークンストレージ）が正しく注入された AuthRepository のインスタンスを提供すること',
      () {
        // 1. Arrange (準備)
        final fakeStorage = FakeTokenStorage();

        // 依存するプロバイダーをモック・フェイクにすり替えたコンテナを作成
        final container = createContainer(fakeStorage);

        // 2. Act (実行)
        // テスト対象のプロバイダーを読み込む
        final repository = container.read(authRepositoryProvider);

        // 3. Assert (検証)
        check(repository).isA<AuthRepository>();

        check(repository.api).equals(mockApi);
        check(repository.tokenStorage).equals(fakeStorage);
      },
    );
  });
}
