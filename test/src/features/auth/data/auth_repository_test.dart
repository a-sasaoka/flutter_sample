import 'dart:async';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:dio/dio.dart'; // Responseクラス用
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/exceptions/reauth_exception.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/auth_session_lock.dart';
import 'package:flutter_sample/src/features/auth/data/custom_auth_invalidation_store.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
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
    this.clearError,
  }) : currentRefreshToken = initialRefreshToken;

  final String? initialRefreshToken;
  String? currentUserId;
  String? currentRefreshToken;
  Future<void> Function(String accessToken, String refreshToken)? onSaveTokens;
  final Exception? clearError;
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
    if (clearError != null) {
      throw clearError!;
    }
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
  late Directory tempDir;
  late CustomAuthInvalidationStore invalidationStore;

  File invalidationMarkerFile() =>
      File(p.join(tempDir.path, CustomAuthInvalidationStore.markerFileName));

  setUpAll(() {
    registerFallbackValue(const AppException.unknown());
    registerFallbackValue(const FileSystemException());
    registerFallbackValue(StackTrace.current);
    registerFallbackValue(Options());
  });

  setUp(() {
    mockApi = MockApiClient();
    mockTalker = MockTalker();
    tempDir = Directory.systemTemp.createTempSync('auth_repository_test_');
    invalidationStore = CustomAuthInvalidationStore(
      getDirectory: () async => tempDir,
    );
    when(() => mockTalker.warning(any<dynamic>())).thenReturn(null);
    when(
      () =>
          mockTalker.handle(any<Object>(), any<StackTrace?>(), any<dynamic>()),
    ).thenReturn(null);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      Process.runSync('chmod', ['755', tempDir.path]);
      tempDir.deleteSync(recursive: true);
    }
  });

  /// 依存関係を注入した ProviderContainer を作成するヘルパー
  ProviderContainer createContainer(FakeTokenStorage fakeStorage) {
    final container = ProviderContainer(
      overrides: [
        authApiClientProvider.overrideWithValue(mockApi),
        // 💡 修正: tokenStorageProvider は Notifier ではないので (ref) => の形でオーバーライドする
        tokenStorageProvider.overrideWith((ref) => fakeStorage),
        appSupportDirectoryReaderProvider.overrideWithValue(
          () async => tempDir,
        ),
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
          invalidationStore: invalidationStore,
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

  group('AuthRepository (reauthenticate & deleteAccount)', () {
    test('getCurrentEmail: 保存済みJWTからemailクレームを取得できること', () async {
      const jwtWithEmail =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiJ1c2VyXzEyMyIsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSJ9.'
          'sig';
      const jwtWithoutEmail =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiJ1c2VyXzEyMyJ9.'
          'sig';

      final fakeStorage = FakeTokenStorage();
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      // トークン未保存時
      check(await repo.getCurrentEmail()).isNull();

      // email クレームあり
      fakeStorage.savedAccessToken = jwtWithEmail;
      check(await repo.getCurrentEmail()).equals('test@example.com');

      // email クレームなし
      fakeStorage.savedAccessToken = jwtWithoutEmail;
      check(await repo.getCurrentEmail()).isNull();
    });

    test('reauthenticate: 成功時に POST /auth/reauthenticate が呼ばれること', () async {
      final fakeStorage = FakeTokenStorage();
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);
      final mockResponse = MockResponse();

      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/reauthenticate',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      await check(
        repo.reauthenticate(email: 'test@example.com', password: 'password123'),
      ).completes();

      verify(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/reauthenticate',
          data: any<dynamic>(
            named: 'data',
            that: equals({
              'email': 'test@example.com',
              'password': 'password123',
            }),
          ),
        ),
      ).called(1);
    });

    test('reauthenticate: DioException(UnauthenticatedException) の場合、 '
        'ReauthWrongPasswordException へ変換され talker.handle は呼ばれないこと', () async {
      final fakeStorage = FakeTokenStorage();
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/reauthenticate',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/reauthenticate'),
          error: const AppException.unauthenticated(),
        ),
      );

      await check(
        repo.reauthenticate(
          email: 'test@example.com',
          password: 'wrong-password',
        ),
      ).throws<ReauthWrongPasswordException>();

      verify(() => mockTalker.warning(any<dynamic>())).called(1);
      verifyNever(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace?>(),
          any<dynamic>(),
        ),
      );
    });

    test('reauthenticate: 直接 UnauthenticatedException が投げられた場合も '
        'ReauthWrongPasswordException へ変換されること', () async {
      final fakeStorage = FakeTokenStorage();
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/reauthenticate',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenThrow(const AppException.unauthenticated());

      await check(
        repo.reauthenticate(
          email: 'test@example.com',
          password: 'wrong-password',
        ),
      ).throws<ReauthWrongPasswordException>();
    });

    test('reauthenticate: 401以外の DioException はそのまま再スローされること', () async {
      final fakeStorage = FakeTokenStorage();
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/reauthenticate',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/reauthenticate'),
          error: const AppException.server(statusCode: 500),
        ),
      );

      await check(
        repo.reauthenticate(email: 'test@example.com', password: 'password123'),
      ).throws<DioException>();
    });

    test('deleteAccount: アクセストークンが無い場合は '
        'UnauthenticatedException を投げること', () async {
      final fakeStorage = FakeTokenStorage();
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      await check(repo.deleteAccount()).throws<UnauthenticatedException>();

      verifyNever(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      );
    });

    test('deleteAccount: 成功時は Bearer ヘッダー付きで削除APIを呼び、 '
        '完了後にトークンを消去すること', () async {
      final fakeStorage = FakeTokenStorage(initialRefreshToken: 'refresh-123')
        ..savedAccessToken = 'access-123'
        ..savedRefreshToken = 'refresh-123'
        ..currentUserId = 'user-123';
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );

      await check(repo.deleteAccount()).completes();

      final captured = verify(
        () => mockApi.delete<void>(
          '/auth/account',
          options: captureAny<Options?>(named: 'options'),
        ),
      ).captured;
      if (captured case [Options(:final headers)]) {
        check(headers?['Authorization']).equals('Bearer access-123');
      } else {
        fail('削除リクエストには Options が必要です: $captured');
      }
      check(fakeStorage.savedAccessToken).isNull();
      check(await fakeStorage.getRefreshToken()).isNull();
      check(fakeStorage.currentUserId).isNull();
    });

    test('deleteAccount: API非同期エラー時は待機中も失敗後も例外を再スローし、トークンを消去しないこと', () async {
      final fakeStorage = FakeTokenStorage(initialRefreshToken: 'refresh-123')
        ..savedAccessToken = 'access-123'
        ..savedRefreshToken = 'refresh-123';
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      final deleteStarted = Completer<void>();
      final deleteCompleter = Completer<Response<void>>();
      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) {
        deleteStarted.complete();
        return deleteCompleter.future;
      });

      final deleteFuture = check(
        repo.deleteAccount(),
      ).throws<ServerException>();
      await deleteStarted.future;

      // 削除 API の応答待ち中はトークンが消去されていないこと
      check(await fakeStorage.getAccessToken()).equals('access-123');
      check(await fakeStorage.getRefreshToken()).equals('refresh-123');

      deleteCompleter.completeError(const AppException.server(statusCode: 500));
      await deleteFuture;

      check(await fakeStorage.getAccessToken()).equals('access-123');
      check(await fakeStorage.getRefreshToken()).equals('refresh-123');
    });

    test('deleteAccount: API待機中に別ユーザーのログインが完了した場合、 '
        '世代不一致のため新しいセッションのトークンを消去しないこと', () async {
      late FakeTokenStorage fakeStorage;
      fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-old',
              onSaveTokens: (accessToken, _) async {
                if (accessToken == 'access-new') {
                  fakeStorage.currentUserId = 'user-new';
                }
              },
            )
            ..savedAccessToken = 'access-old'
            ..savedRefreshToken = 'refresh-old';
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);
      final lock = container.read(authSessionLockProvider);

      final deleteStarted = Completer<void>();
      final deleteCompleter = Completer<Response<void>>();
      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) {
        deleteStarted.complete();
        return deleteCompleter.future;
      });
      final mockLoginResponse = MockResponse();
      when(() => mockLoginResponse.data).thenReturn({
        'access_token': 'access-new',
        'refresh_token': 'refresh-new',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockLoginResponse);

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      // 削除 API 待機中に別ユーザーの新規ログインが完了してセッション世代が進む
      await repo.login('new@example.com', 'password123');
      final epochAfterNewLogin = lock.sessionEpoch;
      check(epochAfterNewLogin).equals(1);

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      await deleteFuture;

      // 新規ログインのトークン・ユーザーIDが維持され、余計な世代更新も起きないこと
      check(await fakeStorage.getAccessToken()).equals('access-new');
      check(await fakeStorage.getRefreshToken()).equals('refresh-new');
      check(await fakeStorage.getUserId()).equals('user-new');
      check(await invalidationStore.isInvalidated()).equals(false);
      check(invalidationMarkerFile().existsSync()).equals(false);
      check(lock.sessionEpoch).equals(epochAfterNewLogin);
    });

    test('deleteAccount: サーバー削除成功後に tokenStorage.clear() が失敗しても、 '
        'talker.handle へ記録して無効化フラグを保持し、次回起動時は未ログインとなること', () async {
      final clearException = Exception('secure storage error');
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-123',
              clearError: clearException,
            )
            ..savedAccessToken = 'access-123'
            ..savedRefreshToken = 'refresh-123'
            ..currentUserId = 'user-123';
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );

      await check(repo.deleteAccount()).completes();

      verify(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).called(1);
      verify(
        () => mockTalker.handle(
          clearException,
          any<StackTrace?>(),
          'Failed to clear local tokens after account deletion',
        ),
      ).called(1);
      check(container.read(authSessionLockProvider).sessionEpoch).equals(1);
      check(await invalidationStore.isInvalidated()).equals(true);
      check(invalidationMarkerFile().existsSync()).equals(true);
      check(await fakeStorage.getAccessToken()).equals('access-123');

      // 次回起動相当の新しい ProviderContainer でもログイン状態へ復元されないこと
      final restartedContainer = createContainer(fakeStorage);
      final restoredAuthState = await restartedContainer.read(
        authStateProvider.future,
      );
      check(restoredAuthState).equals(false);
      check(await invalidationStore.isInvalidated()).equals(true);
    });

    test('deleteAccount: 削除要求前の無効化フラグ保存とトークン消去が両方失敗する場合、 '
        '削除要求を送らず例外を投げトークンが維持されること', () async {
      final clearException = Exception('secure storage error');
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-123',
              clearError: clearException,
            )
            ..savedAccessToken = 'access-123'
            ..savedRefreshToken = 'refresh-123';
      // 一時ファイルパスにディレクトリを配置して実際のディスク書き込みを失敗させる
      Directory(
        p.join(tempDir.path, CustomAuthInvalidationStore.tempFileName),
      ).createSync(recursive: true);
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      await check(repo.deleteAccount()).throws<FileSystemException>();

      verifyNever(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      );
      check(await fakeStorage.getAccessToken()).equals('access-123');
      check(await invalidationStore.isInvalidated()).equals(false);
      check(invalidationMarkerFile().existsSync()).equals(false);
    });

    test('deleteAccount: 削除処理中（API応答待ち）にアプリが終了しても、 '
        '次回起動時はログイン状態へ復元されず残留トークンが消去されること', () async {
      final fakeStorage = FakeTokenStorage(initialRefreshToken: 'refresh-123')
        ..savedAccessToken = 'access-123'
        ..savedRefreshToken = 'refresh-123'
        ..currentUserId = 'user-123';
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      final deleteStarted = Completer<void>();
      final deleteNeverCompletes = Completer<Response<void>>();
      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) {
        deleteStarted.complete();
        return deleteNeverCompletes.future;
      });

      unawaited(repo.deleteAccount());
      await deleteStarted.future;

      check(await invalidationStore.isInvalidated()).equals(true);
      check(invalidationMarkerFile().existsSync()).equals(true);
      check(await fakeStorage.getAccessToken()).equals('access-123');

      // 削除完了前にプロセス終了し、次回起動した想定で別コンテナを生成
      final restartedContainer = createContainer(fakeStorage);
      final restoredAuthState = await restartedContainer.read(
        authStateProvider.future,
      );

      check(restoredAuthState).equals(false);
      check(await fakeStorage.getAccessToken()).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
      check(invalidationMarkerFile().existsSync()).equals(false);
    });

    test('deleteAccount: 削除結果不明のAPI失敗時は同一セッションで再試行でき、 '
        '再試行せず再起動した場合は誤復元しないこと', () async {
      final fakeStorage = FakeTokenStorage(initialRefreshToken: 'refresh-123')
        ..savedAccessToken = 'access-123'
        ..savedRefreshToken = 'refresh-123';
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      var attempts = 0;
      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) {
          throw const AppException.timeout();
        }
        return Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        );
      });

      // 1回目はタイムアウト（結果不明）: トークンは残り同一セッションで再試行可能
      await check(repo.deleteAccount()).throws<TimeoutException>();
      check(await fakeStorage.getAccessToken()).equals('access-123');
      check(await invalidationStore.isInvalidated()).equals(true);
      check(invalidationMarkerFile().existsSync()).equals(true);

      // そのまま再試行して成功した場合はトークンとフラグを両方クリアする
      await check(repo.deleteAccount()).completes();
      check(attempts).equals(2);
      check(await fakeStorage.getAccessToken()).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
      check(invalidationMarkerFile().existsSync()).equals(false);

      // 再度、1回目失敗後に再試行せずアプリ再起動した場合は未ログインとなること
      attempts = 0;
      fakeStorage
        ..savedAccessToken = 'access-retry'
        ..savedRefreshToken = 'refresh-retry';
      await check(repo.deleteAccount()).throws<TimeoutException>();
      final restartedContainer = createContainer(fakeStorage);
      check(
        await restartedContainer.read(authStateProvider.future),
      ).equals(false);
      check(await fakeStorage.getAccessToken()).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
    });

    test('deleteAccount: サーバー削除後に無効化フラグの解除だけ失敗しても記録のみで完了し、 '
        '再ログイン時はフラグを解除すること', () async {
      final fakeStorage = FakeTokenStorage(initialRefreshToken: 'refresh-123')
        ..savedAccessToken = 'access-123'
        ..savedRefreshToken = 'refresh-123';
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) async {
        // 削除要求前に書かれたマーカーを削除できない状態にする
        Process.runSync('chmod', ['555', tempDir.path]);
        return Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        );
      });

      await check(repo.deleteAccount()).completes();

      check(fakeStorage.savedAccessToken).isNull();
      check(invalidationMarkerFile().existsSync()).equals(true);
      verify(
        () => mockTalker.handle(
          any<FileSystemException>(),
          any<StackTrace?>(),
          'Failed to clear invalidated custom auth session flag',
        ),
      ).called(1);

      // 書き込み権限復帰後の別ログインではセッション無効化フラグを確実に解除すること
      Process.runSync('chmod', ['755', tempDir.path]);
      check(await invalidationStore.isInvalidated()).equals(true);
      final mockLoginResponse = MockResponse();
      when(() => mockLoginResponse.data).thenReturn({
        'access_token': 'new-access',
        'refresh_token': 'new-refresh',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockLoginResponse);

      await repo.login('user@example.com', 'password123');
      check(await invalidationStore.isInvalidated()).equals(false);
      check(invalidationMarkerFile().existsSync()).equals(false);
    });
  });
}
