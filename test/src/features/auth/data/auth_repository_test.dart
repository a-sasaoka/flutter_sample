import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:dio/dio.dart'; // Responseクラス用
import 'package:drift/backends.dart';
import 'package:drift/drift.dart' show OpeningDetails;
import 'package:drift/native.dart';
import 'package:flutter_sample/src/app/constants/storage_keys.dart';
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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

// FlutterSecureStorageのモック
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

// CustomAuthInvalidationStoreのモック
class MockCustomAuthInvalidationStore extends Mock
    implements CustomAuthInvalidationStore {}

class _TestQueryExecutorUser implements QueryExecutorUser {
  const _TestQueryExecutorUser();

  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

class _SpyCustomAuthInvalidationStore extends CustomAuthInvalidationStore {
  _SpyCustomAuthInvalidationStore({required super.getDirectory});

  final List<int> markedEntryIds = [];
  final List<int?> clearedEntryIds = [];

  @override
  Future<int> markInvalidated({
    String? targetUserId,
    String? targetEmail,
  }) async {
    final id = await super.markInvalidated(
      targetUserId: targetUserId,
      targetEmail: targetEmail,
    );
    markedEntryIds.add(id);
    return id;
  }

  @override
  Future<void> clearInvalidatedIfMatches({
    required String? targetUserId,
    required String? targetEmail,
    int? entryId,
  }) async {
    clearedEntryIds.add(entryId);
    await super.clearInvalidatedIfMatches(
      targetUserId: targetUserId,
      targetEmail: targetEmail,
      entryId: entryId,
    );
  }
}

// TokenStorageのモック
class FakeTokenStorage extends Mock implements TokenStorage {
  FakeTokenStorage({
    this.initialRefreshToken,
    this.currentUserId,
    this.currentUserEmail,
    this.onSaveTokens,
    this.clearError,
  }) : currentRefreshToken = initialRefreshToken;

  final String? initialRefreshToken;
  String? currentUserId;
  String? currentUserEmail;
  String? currentRefreshToken;
  Future<void> Function(String accessToken, String refreshToken)? onSaveTokens;
  Exception? clearError;
  Exception? getAccessTokenError;
  Exception? getUserIdError;
  Exception? getUserEmailError;
  int getUserIdCalls = 0;
  int saveTokensCalls = 0;

  // 保存された値を検証するためのプロパティ
  String? savedAccessToken;
  String? savedRefreshToken;

  @override
  Future<String?> getUserId() async {
    getUserIdCalls++;
    if (getUserIdError != null) {
      throw getUserIdError!;
    }
    return currentUserId;
  }

  @override
  Future<String?> getUserEmail() async {
    if (getUserEmailError case final Exception error) {
      throw error;
    }
    return currentUserEmail;
  }

  @override
  Future<String?> getAccessToken() async {
    if (getAccessTokenError != null) {
      throw getAccessTokenError!;
    }
    return savedAccessToken;
  }

  @override
  Future<String?> getRefreshToken() async => currentRefreshToken;

  @override
  Future<void> clear() async {
    if (clearError != null) {
      throw clearError!;
    }
    currentUserId = null;
    currentUserEmail = null;
    currentRefreshToken = null;
    savedAccessToken = null;
    savedRefreshToken = null;
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
    String? email,
    bool preserveExistingOnFailure = false,
  }) async {
    saveTokensCalls++;
    savedAccessToken = accessToken;
    savedRefreshToken = refreshToken;
    currentRefreshToken = refreshToken;
    currentUserId = userId;
    currentUserEmail = email;
    await onSaveTokens?.call(accessToken, refreshToken);
  }
}

void main() {
  late MockApiClient mockApi;
  late MockTalker mockTalker;
  late Directory tempDir;
  late CustomAuthInvalidationStore invalidationStore;

  File invalidationDbFile() =>
      File(p.join(tempDir.path, CustomAuthInvalidationStore.databaseFileName));

  String buildJwt({String? sub, String? email, String? jti}) {
    final header = base64Url.encode(
      utf8.encode(jsonEncode({'alg': 'none', 'typ': 'JWT'})),
    );
    final payloadMap = <String, Object?>{
      'sub': ?sub,
      'email': ?email,
      'jti': ?jti,
    };
    final payload = base64Url.encode(utf8.encode(jsonEncode(payloadMap)));
    return '$header.$payload.sig';
  }

  setUpAll(() {
    registerFallbackValue(const AppException.unknown());
    registerFallbackValue(SqliteException(0, ''));
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
      Process.runSync('chmod', ['-R', '755', tempDir.path]);
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

  /// MockFlutterSecureStorage の名前付き引数から key を型パターンで取り出すヘルパー
  String extractStorageKey(String operation, Invocation inv) =>
      switch (inv.namedArguments) {
        {#key: final String key} => key,
        _ => fail('Unexpected $operation arguments: ${inv.namedArguments}'),
      };

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
      final loggedIn = await repo.login('test@example.com', 'password123');

      // Assert
      check(loggedIn).equals(true);
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

    test('login: 削除前に開始した要求の応答が deleteAccount 完了後に届いた場合は破棄して '
        'トークンを保存せず false を返し、削除後の新規ログインは成功すること', () async {
      final fakeStorage = FakeTokenStorage(initialRefreshToken: 'old-refresh')
        ..savedAccessToken = 'old-access'
        ..savedRefreshToken = 'old-refresh'
        ..currentUserId = 'user-old';
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);
      final lock = container.read(authSessionLockProvider);

      final staleLoginStarted = Completer<void>();
      final staleLoginGate = Completer<Map<String, dynamic>>();
      var loginCalls = 0;
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async {
        loginCalls++;
        final response = MockResponse();
        if (loginCalls == 1) {
          staleLoginStarted.complete();
          final data = await staleLoginGate.future;
          when(() => response.data).thenReturn(data);
        } else {
          when(() => response.data).thenReturn({
            'access_token': 'fresh-access',
            'refresh_token': 'fresh-refresh',
          });
        }
        return response;
      });
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

      final staleLoginFuture = repo.login('stale@example.com', 'password123');
      await staleLoginStarted.future;

      check(await repo.deleteAccount()).equals(true);
      check(lock.deletionEpoch).equals(1);
      final epochAfterDelete = lock.sessionEpoch;

      staleLoginGate.complete({
        'access_token': 'stale-access',
        'refresh_token': 'stale-refresh',
      });

      check(await staleLoginFuture).equals(false);
      check(fakeStorage.savedAccessToken).isNull();
      check(fakeStorage.savedRefreshToken).isNull();
      check(lock.sessionEpoch).equals(epochAfterDelete);
      check(lock.deletionEpoch).equals(1);

      // 削除完了後に新しく開始したログイン要求は通常どおり成功すること
      check(await repo.login('fresh@example.com', 'password123')).equals(true);
      check(fakeStorage.savedAccessToken).equals('fresh-access');
      check(fakeStorage.savedRefreshToken).equals('fresh-refresh');

      // 呼び出し元が古い startSessionEpoch / startDeletionEpoch を渡した場合は保存せず false を返すこと
      final saveCallsBeforeStaleRetry = fakeStorage.saveTokensCalls;
      check(
        await repo.login(
          'stale-caller@example.com',
          'password123',
          startSessionEpoch: epochAfterDelete - 1,
          startDeletionEpoch: 0,
        ),
      ).equals(false);
      check(fakeStorage.saveTokensCalls).equals(saveCallsBeforeStaleRetry);
      check(fakeStorage.savedAccessToken).equals('fresh-access');
      check(fakeStorage.savedRefreshToken).equals('fresh-refresh');
    });

    test('login: 無効化状態の確認・解除(clearIfAllowedForLogin)に失敗した場合は '
        'saveTokens を実行せずトークンを残さないこと', () async {
      var saveCalled = false;
      final fakeStorage = FakeTokenStorage(
        onSaveTokens: (_, _) async {
          saveCalled = true;
        },
      );
      invalidationDbFile().writeAsStringSync('invalid sqlite bytes');
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      final mockResponse = MockResponse();
      when(() => mockResponse.data).thenReturn({
        'access_token': buildJwt(sub: 'user-a', email: 'a@example.com'),
        'refresh_token': 'refresh-a',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      await check(
        repo.login('a@example.com', 'password123'),
      ).throws<SqliteException>();

      check(saveCalled).equals(false);
      check(fakeStorage.savedAccessToken).isNull();
      check(fakeStorage.savedRefreshToken).isNull();
    });

    test('login: markLoginPending 失敗時は clearIfAllowedForLogin と '
        'saveTokens を実行しないこと', () async {
      final callOrder = <String>[];
      var saveCalled = false;
      final fakeStorage = FakeTokenStorage(
        onSaveTokens: (_, _) async {
          saveCalled = true;
        },
      );
      final mockStore = MockCustomAuthInvalidationStore();
      final markError = Exception('markLoginPending failed');
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);
      when(mockStore.markLoginPending).thenAnswer((_) async {
        callOrder.add('markLoginPending');
        throw markError;
      });
      when(
        () => mockStore.clearIfAllowedForLogin(
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          isDeletionInProgress: any(named: 'isDeletionInProgress'),
        ),
      ).thenAnswer((_) async {
        callOrder.add('clearIfAllowedForLogin');
        return true;
      });

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          customAuthInvalidationStoreProvider.overrideWithValue(mockStore),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      final mockResponse = MockResponse();
      when(() => mockResponse.data).thenReturn({
        'access_token': buildJwt(sub: 'user-a', email: 'a@example.com'),
        'refresh_token': 'refresh-a',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      await check(
        container.read(authRepositoryProvider).login('a@example.com', 'pw'),
      ).throws<Exception>((it) => it.equals(markError));

      check(callOrder).deepEquals(['markLoginPending']);
      check(saveCalled).equals(false);
      verifyNever(
        () => mockStore.clearIfAllowedForLogin(
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          isDeletionInProgress: any(named: 'isDeletionInProgress'),
        ),
      );
    });

    test('login: markLoginPending 成功後に clearIfAllowedForLogin が失敗しても、 '
        'saveTokens へ進まず未確定マーカーを残すこと', () async {
      final callOrder = <String>[];
      var saveCalled = false;
      final fakeStorage = FakeTokenStorage(
        onSaveTokens: (_, _) async {
          saveCalled = true;
        },
      );
      final mockStore = MockCustomAuthInvalidationStore();
      final clearAllowedError = Exception('clearIfAllowedForLogin failed');
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);
      when(mockStore.markLoginPending).thenAnswer((_) async {
        callOrder.add('markLoginPending');
      });
      when(
        () => mockStore.clearIfAllowedForLogin(
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          isDeletionInProgress: any(named: 'isDeletionInProgress'),
        ),
      ).thenAnswer((_) async {
        callOrder.add('clearIfAllowedForLogin');
        throw clearAllowedError;
      });

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          customAuthInvalidationStoreProvider.overrideWithValue(mockStore),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      final mockResponse = MockResponse();
      when(() => mockResponse.data).thenReturn({
        'access_token': buildJwt(sub: 'user-a', email: 'a@example.com'),
        'refresh_token': 'refresh-a',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      await check(
        container.read(authRepositoryProvider).login('a@example.com', 'pw'),
      ).throws<Exception>((it) => it.equals(clearAllowedError));

      check(
        callOrder,
      ).deepEquals(['markLoginPending', 'clearIfAllowedForLogin']);
      check(saveCalled).equals(false);
      verifyNever(mockStore.clearLoginPending);
    });

    test('login: saveTokens が途中まで進んだ後に失敗した場合でも、ロールバックにより '
        '新しいトークンがストレージに残らないこと', () async {
      final partialSaveError = Exception('partial write failed');
      final fakeStorage = FakeTokenStorage(
        onSaveTokens: (_, _) => throw partialSaveError,
      );
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      final mockResponse = MockResponse();
      when(() => mockResponse.data).thenReturn({
        'access_token': buildJwt(sub: 'user-a', email: 'a@example.com'),
        'refresh_token': 'refresh-a',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      await check(
        repo.login('a@example.com', 'password123'),
      ).throws<Exception>((it) => it.equals(partialSaveError));

      check(fakeStorage.savedAccessToken).isNull();
      check(fakeStorage.savedRefreshToken).isNull();
      check(fakeStorage.currentUserId).isNull();
    });

    test('login: 部分保存失敗時のロールバック消去にも失敗した場合は '
        'talker.handle に記録しつつ元の保存失敗例外を再スローし、再起動時も復元しないこと', () async {
      final partialSaveError = Exception('partial write failed');
      final clearError = Exception('rollback clear failed');
      final fakeStorage = FakeTokenStorage(
        onSaveTokens: (_, _) => throw partialSaveError,
        clearError: clearError,
      );
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      final mockResponse = MockResponse();
      when(() => mockResponse.data).thenReturn({
        'access_token': buildJwt(sub: 'user-a', email: 'a@example.com'),
        'refresh_token': 'refresh-a',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      await check(
        repo.login('a@example.com', 'password123'),
      ).throws<Exception>((it) => it.equals(partialSaveError));

      verify(
        () => mockTalker.handle(
          clearError,
          any<StackTrace?>(),
          'Failed to clear partial login tokens after saveTokens error',
        ),
      ).called(1);
      check(fakeStorage.savedAccessToken).isNotNull();
      check(await invalidationStore.isLoginPending()).equals(true);

      // 消去失敗によりトークンが残存したまま再起動しても未ログイン(false)と判定されること
      final restartedContainer = createContainer(fakeStorage);
      check(
        await restartedContainer.read(authStateProvider.future),
      ).equals(false);
      check(await invalidationStore.isLoginPending()).equals(true);

      // ストレージ回復後の次回起動で残留トークンと未確定フラグが消去されること
      fakeStorage.clearError = null;
      final recoveredContainer = createContainer(fakeStorage);
      check(
        await recoveredContainer.read(authStateProvider.future),
      ).equals(false);
      check(fakeStorage.savedAccessToken).isNull();
      check(await invalidationStore.isLoginPending()).equals(false);
    });

    test('login: 退会進行中に別アカウントのログインが部分保存失敗＋消去失敗しても、 '
        '退会側の無効化レコードを上書き・消失させないこと', () async {
      final tokenA = buildJwt(sub: 'user-a', email: 'a@example.com');
      final tokenB = buildJwt(sub: 'user-b', email: 'b@example.com');
      final partialSaveError = Exception('partial write failed');
      final clearError = Exception('rollback clear failed');
      final fakeStorage = FakeTokenStorage(initialRefreshToken: 'refresh-a')
        ..savedAccessToken = tokenA
        ..savedRefreshToken = 'refresh-a'
        ..currentUserId = 'user-a';
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
      final mockLoginResponse = MockResponse();
      when(
        () => mockLoginResponse.data,
      ).thenReturn({'access_token': tokenB, 'refresh_token': 'refresh-b'});
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockLoginResponse);

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      fakeStorage
        ..clearError = clearError
        ..onSaveTokens = (_, _) async => throw partialSaveError;
      await check(
        repo.login('b@example.com', 'password123'),
      ).throws<Exception>((it) => it.equals(partialSaveError));

      // 退会側の無効化レコード(user-a)と未確定ログインフラグが独立して両方維持されること
      final invalidationState = await invalidationStore.getInvalidationState();
      check(invalidationState.isInvalidated).equals(true);
      check(invalidationState.targetUserId).equals('user-a');
      check(await invalidationStore.isLoginPending()).equals(true);

      // ストレージ回復状態でそのまま再起動した場合も安全に両方消去され false になること
      fakeStorage
        ..clearError = null
        ..onSaveTokens = null;
      final restartedContainer = createContainer(fakeStorage);
      check(
        await restartedContainer.read(authStateProvider.future),
      ).equals(false);
      check(fakeStorage.savedAccessToken).isNull();
      check(await invalidationStore.isLoginPending()).equals(false);
      check(await invalidationStore.isInvalidated()).equals(false);

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      await deleteFuture;
    });

    test('login: clearLogoutPending() を clearLoginPending() より先に実行し、 '
        '両方の完了後にログインを確定すること', () async {
      final callOrder = <String>[];
      final clearLogoutStarted = Completer<void>();
      final clearLogoutGate = Completer<void>();
      final clearLoginStarted = Completer<void>();
      final clearLoginGate = Completer<void>();
      final fakeStorage = FakeTokenStorage(
        onSaveTokens: (_, _) async {
          callOrder.add('saveTokens');
        },
      );
      final mockStore = MockCustomAuthInvalidationStore();
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);
      when(mockStore.markLoginPending).thenAnswer((_) async {
        callOrder.add('markLoginPending');
      });
      when(
        () => mockStore.clearIfAllowedForLogin(
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          isDeletionInProgress: any(named: 'isDeletionInProgress'),
        ),
      ).thenAnswer((_) async {
        callOrder.add('clearIfAllowedForLogin');
        return true;
      });
      when(mockStore.clearLogoutPending).thenAnswer((_) async {
        callOrder.add('clearLogoutPending');
        clearLogoutStarted.complete();
        await clearLogoutGate.future;
      });
      when(mockStore.clearLoginPending).thenAnswer((_) async {
        callOrder.add('clearLoginPending');
        clearLoginStarted.complete();
        await clearLoginGate.future;
      });

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          customAuthInvalidationStoreProvider.overrideWithValue(mockStore),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      final mockResponse = MockResponse();
      when(() => mockResponse.data).thenReturn({
        'access_token': buildJwt(sub: 'user-a', email: 'a@example.com'),
        'refresh_token': 'refresh-a',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      var loginCompleted = false;
      final loginFuture = container
          .read(authRepositoryProvider)
          .login('a@example.com', 'password123');
      unawaited(loginFuture.then((_) => loginCompleted = true));

      await clearLogoutStarted.future;
      await Future<void>.delayed(Duration.zero);

      // clearLogoutPending() の完了前は clearLoginPending() が開始せず、login() も完了しないこと
      check(clearLoginStarted.isCompleted).equals(false);
      check(loginCompleted).equals(false);
      check(callOrder).deepEquals([
        'markLoginPending',
        'clearIfAllowedForLogin',
        'saveTokens',
        'clearLogoutPending',
      ]);

      clearLogoutGate.complete();
      await clearLoginStarted.future;
      await Future<void>.delayed(Duration.zero);

      // clearLoginPending() の完了前は login() が成功を返さないこと
      check(loginCompleted).equals(false);
      check(callOrder).deepEquals([
        'markLoginPending',
        'clearIfAllowedForLogin',
        'saveTokens',
        'clearLogoutPending',
        'clearLoginPending',
      ]);

      clearLoginGate.complete();
      check(await loginFuture).equals(true);
      check(loginCompleted).equals(true);
    });

    test('login: clearLogoutPending() 失敗かつロールバック clear() 失敗時は '
        'clearLoginPending() を呼ばず loginPending を保持して再起動復元を防ぐこと', () async {
      final clearLogoutError = Exception('clearLogoutPending failed');
      final clearTokensError = Exception('rollback clear failed');
      final fakeStorage = FakeTokenStorage(clearError: clearTokensError);
      final mockStore = MockCustomAuthInvalidationStore();
      var isLoginPending = false;
      when(mockStore.isLoginPending).thenAnswer((_) async => isLoginPending);
      when(mockStore.isLogoutPending).thenAnswer((_) async => false);
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);
      when(mockStore.markLoginPending).thenAnswer((_) async {
        isLoginPending = true;
      });
      when(
        () => mockStore.clearIfAllowedForLogin(
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          isDeletionInProgress: any(named: 'isDeletionInProgress'),
        ),
      ).thenAnswer((_) async => true);
      when(mockStore.clearLogoutPending).thenThrow(clearLogoutError);
      when(mockStore.clearLoginPending).thenAnswer((_) async {
        isLoginPending = false;
      });

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          customAuthInvalidationStoreProvider.overrideWithValue(mockStore),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      final mockResponse = MockResponse();
      when(() => mockResponse.data).thenReturn({
        'access_token': buildJwt(sub: 'user-a', email: 'a@example.com'),
        'refresh_token': 'refresh-a',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      await check(
        container
            .read(authRepositoryProvider)
            .login('a@example.com', 'password123'),
      ).throws<Exception>((it) => it.equals(clearLogoutError));

      verifyNever(mockStore.clearLoginPending);
      check(isLoginPending).equals(true);
      check(fakeStorage.savedAccessToken).isNotNull();

      final restarted = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          customAuthInvalidationStoreProvider.overrideWithValue(mockStore),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(restarted.dispose);
      check(await restarted.read(authStateProvider.future)).equals(false);
      check(isLoginPending).equals(true);
    });

    test('login: clearLogoutPending() 失敗後にロールバックで全キーを消去できた場合は '
        '消去後にのみ保留を解除すること', () async {
      final clearLogoutError = Exception('transient clearLogoutPending failed');
      final fakeStorage = FakeTokenStorage();
      final mockStore = MockCustomAuthInvalidationStore();
      final callOrder = <String>[];
      var isLoginPending = false;
      var clearLogoutCalls = 0;
      when(mockStore.isLoginPending).thenAnswer((_) async => isLoginPending);
      when(mockStore.isLogoutPending).thenAnswer((_) async => false);
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);
      when(mockStore.markLoginPending).thenAnswer((_) async {
        isLoginPending = true;
      });
      when(
        () => mockStore.clearIfAllowedForLogin(
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          isDeletionInProgress: any(named: 'isDeletionInProgress'),
        ),
      ).thenAnswer((_) async => true);
      when(mockStore.clearLogoutPending).thenAnswer((_) async {
        clearLogoutCalls++;
        if (clearLogoutCalls == 1) {
          check(fakeStorage.savedAccessToken).isNotNull();
          callOrder.add('clearLogoutPending:initial');
          throw clearLogoutError;
        }
        check(fakeStorage.savedAccessToken).isNull();
        callOrder.add('clearLogoutPending:rollback');
      });
      when(mockStore.clearLoginPending).thenAnswer((_) async {
        check(fakeStorage.savedAccessToken).isNull();
        callOrder.add('clearLoginPending:rollback');
        isLoginPending = false;
      });

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          customAuthInvalidationStoreProvider.overrideWithValue(mockStore),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      final mockResponse = MockResponse();
      when(() => mockResponse.data).thenReturn({
        'access_token': buildJwt(sub: 'user-a', email: 'a@example.com'),
        'refresh_token': 'refresh-a',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      await check(
        container
            .read(authRepositoryProvider)
            .login('a@example.com', 'password123'),
      ).throws<Exception>((it) => it.equals(clearLogoutError));

      check(fakeStorage.savedAccessToken).isNull();
      check(isLoginPending).equals(false);
      check(callOrder).deepEquals([
        'clearLogoutPending:initial',
        'clearLogoutPending:rollback',
        'clearLoginPending:rollback',
      ]);
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

      test('refreshToken経由で saveTokens が途中失敗した場合は既存資格情報を復元し、 '
          'login経路で途中失敗した場合は部分書込を削除すること', () async {
        final store = <String, String>{
          SecureStorageKeys.accessToken: buildJwt(sub: 'user-a'),
          SecureStorageKeys.refreshToken: 'valid-refresh',
          SecureStorageKeys.customUserId: 'user-a',
        };
        final mockSecureStorage = MockFlutterSecureStorage();
        when(
          () => mockSecureStorage.read(key: any(named: 'key')),
        ).thenAnswer((inv) async => store[inv.namedArguments[#key] as String]);
        when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer(
          (inv) async {
            store.remove(inv.namedArguments[#key] as String);
          },
        );

        final refreshWriteError = Exception('refresh write failed');
        when(
          () => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((inv) async {
          final (:key, :value) = switch (inv.namedArguments) {
            {#key: final String key, #value: final String? value} => (
              key: key,
              value: value,
            ),
            _ => fail('Unexpected write arguments: ${inv.namedArguments}'),
          };
          if (key == SecureStorageKeys.refreshToken &&
              value == 'valid-refresh') {
            throw refreshWriteError;
          }
          if (value == null) {
            store.remove(key);
          } else {
            store[key] = value;
          }
        });

        final realStorage = TokenStorage(secureStorage: mockSecureStorage);
        final container = ProviderContainer(
          overrides: [
            authApiClientProvider.overrideWithValue(mockApi),
            tokenStorageProvider.overrideWith((ref) => realStorage),
            appSupportDirectoryReaderProvider.overrideWithValue(
              () async => tempDir,
            ),
            loggerProvider.overrideWithValue(mockTalker),
          ],
        );
        addTearDown(container.dispose);
        final repo = container.read(authRepositoryProvider);

        final newAccess = buildJwt(sub: 'user-a', email: 'new@example.com');
        final refreshResponse = MockResponse();
        when(
          () => refreshResponse.data,
        ).thenReturn({'access_token': newAccess});
        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async => refreshResponse);

        // ① refreshToken 経路の途中失敗では書き込み前の accessToken が復元され、
        //    有効な refreshToken / customUserId も削除されず保持されること
        final previousAccess = store[SecureStorageKeys.accessToken];
        await check(
          repo.refreshToken('user-a'),
        ).throws<Exception>((it) => it.equals(refreshWriteError));
        check(store[SecureStorageKeys.accessToken]).equals(previousAccess);
        check(store[SecureStorageKeys.refreshToken]).equals('valid-refresh');
        check(store[SecureStorageKeys.customUserId]).equals('user-a');

        // ② login 経路の途中失敗では部分的に書き込まれた資格情報が削除されること
        store.clear();
        final loginResponse = MockResponse();
        when(() => loginResponse.data).thenReturn({
          'access_token': buildJwt(sub: 'user-b'),
          'refresh_token': 'valid-refresh',
        });
        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/login',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async => loginResponse);

        await check(
          repo.login('b@example.com', 'password123'),
        ).throws<Exception>((it) => it.equals(refreshWriteError));
        check(store).isEmpty();
      });

      test('logout保留中(isLogoutPending)の間は refreshToken がAPI呼び出し・再保存を抑止すること '
          '(userId が null / 非null の双方)', () async {
        final fakeStorage = FakeTokenStorage(initialRefreshToken: 'refresh-a')
          ..savedRefreshToken = 'refresh-a';
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        await invalidationStore.markLogoutPending();

        // 1. accessToken / customUserId が消去済みで currentUserId == null の場合
        check(await repo.refreshToken(null)).equals(false);

        // 2. customUserId が残留している場合
        fakeStorage.currentUserId = 'user-a';
        check(await repo.refreshToken('user-a')).equals(false);

        verifyNever(
          () => mockApi.post<Map<String, dynamic>>(
            any(),
            data: any<dynamic>(named: 'data'),
          ),
        );
        check(fakeStorage.savedAccessToken).isNull();
      });

      test(
        'login保留中(isLoginPending)の間は refreshToken がAPI呼び出し・再保存を抑止すること',
        () async {
          final fakeStorage = FakeTokenStorage(initialRefreshToken: 'refresh-a')
            ..savedRefreshToken = 'refresh-a';
          final container = createContainer(fakeStorage);
          final repo = container.read(authRepositoryProvider);

          await invalidationStore.markLoginPending();

          check(await repo.refreshToken(null)).equals(false);
          verifyNever(
            () => mockApi.post<Map<String, dynamic>>(
              any(),
              data: any<dynamic>(named: 'data'),
            ),
          );
          check(fakeStorage.savedAccessToken).isNull();
        },
      );

      test('退会完了後のトークン消去失敗で無効化レコードが残存している間は '
          'refreshToken が資格情報を再保存しないこと', () async {
        final jwtA = buildJwt(sub: 'user-a', email: 'a@example.com');
        final fakeStorage =
            FakeTokenStorage(
                initialRefreshToken: 'refresh-a',
                currentUserId: 'user-a',
                clearError: Exception('clear failed'),
              )
              ..savedAccessToken = jwtA
              ..savedRefreshToken = 'refresh-a';
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

        check(await repo.deleteAccount()).equals(true);
        check(await invalidationStore.isInvalidated()).equals(true);

        // 1. 消去失敗後に全キー残留している場合
        check(await repo.refreshToken('user-a')).equals(false);
        check(fakeStorage.savedAccessToken).equals(jwtA);

        // 2. accessToken / customUserId のみ消去済みで refreshToken が残留した場合
        fakeStorage
          ..savedAccessToken = null
          ..currentUserId = null;
        check(await repo.refreshToken(null)).equals(false);
        check(fakeStorage.savedAccessToken).isNull();

        verifyNever(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        );
      });

      test('退会処理中かつ accessToken 欠損時は refreshToken(null) を拒否すること', () async {
        final jwtA = buildJwt(sub: 'user-a', email: 'a@example.com');
        final fakeStorage =
            FakeTokenStorage(
                initialRefreshToken: 'refresh-a',
                currentUserId: 'user-a',
              )
              ..savedAccessToken = jwtA
              ..savedRefreshToken = 'refresh-a';
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

        final deleteFuture = repo.deleteAccount();
        await deleteStarted.future;

        await container.read(authSessionLockProvider).synchronized(() async {
          fakeStorage
            ..savedAccessToken = null
            ..currentUserId = null;
        });

        check(await repo.refreshToken(null)).equals(false);
        check(fakeStorage.savedAccessToken).isNull();
        verifyNever(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        );

        deleteCompleter.complete(
          Response<void>(
            requestOptions: RequestOptions(path: '/auth/account'),
            statusCode: 200,
          ),
        );
        await deleteFuture;
      });

      test('リフレッシュ通信中に成否不明の退会失敗が発生して無効化レコードが残った場合は '
          '保存を抑止して false を返すこと', () async {
        final jwtA = buildJwt(sub: 'user-a', email: 'a@example.com');
        final fakeStorage =
            FakeTokenStorage(
                initialRefreshToken: 'refresh-a',
                currentUserId: 'user-a',
              )
              ..savedAccessToken = jwtA
              ..savedRefreshToken = 'refresh-a';
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
          () => mockApi.delete<void>(
            '/auth/account',
            options: any<Options?>(named: 'options'),
          ),
        ).thenThrow(const AppException.network());

        final refreshFuture = repo.refreshToken('user-a');
        await refreshStarted.future;

        await check(repo.deleteAccount()).throws<NetworkException>();
        check(await invalidationStore.isInvalidated()).equals(true);

        refreshGate.complete({'access_token': 'refreshed_access_a'});
        check(await refreshFuture).equals(false);
        check(fakeStorage.savedAccessToken).equals(jwtA);
      });

      test(
        '退会処理が非進行中に別アカウント確定済みの無効化行のみ残存している場合は '
        '無視して refreshToken が成功すること (JWT・trackedEmail・保存済みメールフォールバック)',
        () async {
          final jwtB = buildJwt(sub: 'user-b', email: 'b@example.com');
          final fakeStorage =
              FakeTokenStorage(
                  initialRefreshToken: 'refresh-b',
                  currentUserId: 'user-b',
                  currentUserEmail: 'b@example.com',
                )
                ..savedAccessToken = jwtB
                ..savedRefreshToken = 'refresh-b';
          final container = createContainer(fakeStorage);
          final repo = container.read(authRepositoryProvider);

          await invalidationStore.markInvalidated(
            targetUserId: 'user-a',
            targetEmail: 'a@example.com',
          );

          final refreshedJwtB = buildJwt(sub: 'user-b', email: 'b@example.com');
          final mockResponse = MockResponse();
          when(
            () => mockResponse.data,
          ).thenReturn({'access_token': refreshedJwtB});
          when(
            () => mockApi.post<Map<String, dynamic>>(
              '/auth/refresh',
              data: any<dynamic>(named: 'data'),
            ),
          ).thenAnswer((_) async => mockResponse);

          // 1. JWT の sub / email が別アカウント(user-b / b@example.com)と確定する場合
          check(await repo.refreshToken('user-b')).equals(true);
          check(fakeStorage.savedAccessToken).equals(refreshedJwtB);

          // 2. sub/email なしアクセストークンでもロック内 trackedEmail で別アカウントと確定する場合
          final loginResponse = MockResponse();
          when(() => loginResponse.data).thenReturn({
            'access_token': 'opaque-access-b',
            'refresh_token': 'refresh-b2',
          });
          when(
            () => mockApi.post<Map<String, dynamic>>(
              '/auth/login',
              data: any<dynamic>(named: 'data'),
            ),
          ).thenAnswer((_) async => loginResponse);
          check(await repo.login('b@example.com', 'password123')).equals(true);
          // login() の clearIfAllowedForLogin 後に別アカウント行が再残存・未削除だったケースを再現
          await invalidationStore.markInvalidated(
            targetUserId: 'user-a',
            targetEmail: 'a@example.com',
          );
          when(
            () => mockResponse.data,
          ).thenReturn({'access_token': 'refreshed-opaque-b'});
          check(await repo.refreshToken(null)).equals(true);
          check(fakeStorage.savedAccessToken).equals('refreshed-opaque-b');

          // 3. sub/email なしトークンかつ trackedEmail 未保持でも TokenStorage 保存済みメールで確定する場合
          fakeStorage
            ..savedAccessToken = 'reloaded-opaque-b'
            ..currentUserId = null
            ..currentUserEmail = 'b@example.com';
          when(
            () => mockResponse.data,
          ).thenReturn({'access_token': 'refreshed-reloaded-opaque-b'});
          check(await repo.refreshToken(null)).equals(true);
          check(
            fakeStorage.savedAccessToken,
          ).equals('refreshed-reloaded-opaque-b');
        },
      );

      test('退会処理が非進行中に判定不能または現アカウント一致の無効化行が残存している場合は '
          '別アカウント行が混在していても refreshToken を拒否すること', () async {
        final jwtB = buildJwt(sub: 'user-b', email: 'b@example.com');
        final fakeStorage =
            FakeTokenStorage(
                initialRefreshToken: 'refresh-b',
                currentUserId: 'user-b',
                currentUserEmail: 'b@example.com',
              )
              ..savedAccessToken = jwtB
              ..savedRefreshToken = 'refresh-b';
        final container = createContainer(fakeStorage);
        final repo = container.read(authRepositoryProvider);

        // 1. 識別不能 (targetUserId == null && targetEmail == null) な無効化行は拒否
        final unknownEntryId = await invalidationStore.markInvalidated();
        check(await repo.refreshToken('user-b')).equals(false);
        await invalidationStore.clearInvalidatedIfMatches(
          targetUserId: null,
          targetEmail: null,
          entryId: unknownEntryId,
        );

        // 2. 別アカウント行(user-a)と現アカウント一致行(user-b)が混在する場合は拒否
        await invalidationStore.markInvalidated(
          targetUserId: 'user-a',
          targetEmail: 'a@example.com',
        );
        final bEntryId = await invalidationStore.markInvalidated(
          targetUserId: 'user-b',
          targetEmail: 'b@example.com',
        );
        check(await repo.refreshToken('user-b')).equals(false);
        await invalidationStore.clearInvalidatedIfMatches(
          targetUserId: 'user-b',
          targetEmail: 'b@example.com',
          entryId: bEntryId,
        );

        // 3. ID のみを持つ無効化行に対し現セッションがメールのみの場合は照合不能のため拒否
        fakeStorage
          ..savedAccessToken = 'opaque-only-email-b'
          ..currentUserId = null
          ..currentUserEmail = 'b@example.com';
        await invalidationStore.clearInvalidatedIfMatches(
          targetUserId: 'user-a',
          targetEmail: 'a@example.com',
        );
        await invalidationStore.markInvalidated(targetUserId: 'user-a');
        check(await repo.refreshToken(null)).equals(false);

        check(fakeStorage.savedAccessToken).equals('opaque-only-email-b');
        verifyNever(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: any<dynamic>(named: 'data'),
          ),
        );
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

      // email クレームなし・保存済みメールあり
      fakeStorage
        ..savedAccessToken = jwtWithoutEmail
        ..currentUserEmail = 'persisted@example.com';
      check(await repo.getCurrentEmail()).equals('persisted@example.com');

      // トークン未保存時は保存済みメールがあっても null
      fakeStorage.savedAccessToken = null;
      check(await repo.getCurrentEmail()).isNull();

      // email クレームなし・保存済みメールなし
      fakeStorage
        ..savedAccessToken = jwtWithoutEmail
        ..currentUserEmail = null;
      check(await repo.getCurrentEmail()).isNull();
    });

    test('getCurrentEmail: _sessionLock で直列化され資格情報更新完了後に '
        '既存優先順位で取得できること', () async {
      final opaqueA = buildJwt(jti: 'opaque-a');
      final opaqueB = buildJwt(jti: 'opaque-b');
      final fakeStorage = FakeTokenStorage()
        ..savedAccessToken = opaqueA
        ..currentUserEmail = 'a@example.com';
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);
      // trackedEmailForAccessToken が tokenStorage.getUserEmail より優先されること
      final lock = container.read(authSessionLockProvider)
        ..recordAuthenticatedSession(
          accessToken: opaqueA,
          email: 'tracked-a@example.com',
        );
      check(await repo.getCurrentEmail()).equals('tracked-a@example.com');

      // ロック保持中の資格情報更新（A -> B）完了まで待機し、途中の古いメールを返さないこと
      final transitionGate = Completer<void>();
      var isEmailUpdated = false;
      final transitionFuture = lock.runSessionTransition(() async {
        fakeStorage.savedAccessToken = opaqueB;
        await transitionGate.future;
        fakeStorage.currentUserEmail = 'b@example.com';
        lock.recordAuthenticatedSession(
          accessToken: opaqueB,
          email: 'b@example.com',
        );
        isEmailUpdated = true;
      });

      final emailFuture = repo.getCurrentEmail();
      await Future<void>.delayed(Duration.zero);
      check(isEmailUpdated).equals(false);

      transitionGate.complete();
      await transitionFuture;
      check(await emailFuture).equals('b@example.com');
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

      await check(repo.deleteAccount()).completes((it) => it.equals(true));

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
      final oldJwt = buildJwt(sub: 'user-old', email: 'old@example.com');
      final newJwt = buildJwt(sub: 'user-new', email: 'new@example.com');
      late FakeTokenStorage fakeStorage;
      fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-old',
              onSaveTokens: (accessToken, _) async {
                if (accessToken == newJwt) {
                  fakeStorage.currentUserId = 'user-new';
                }
              },
            )
            ..savedAccessToken = oldJwt
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
      when(
        () => mockLoginResponse.data,
      ).thenReturn({'access_token': newJwt, 'refresh_token': 'refresh-new'});
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
      check(await deleteFuture).equals(false);

      // 新規ログインのトークン・ユーザーIDが維持され、余計な世代更新も起きないこと
      check(await fakeStorage.getAccessToken()).equals(newJwt);
      check(await fakeStorage.getRefreshToken()).equals('refresh-new');
      check(await fakeStorage.getUserId()).equals('user-new');
      check(await invalidationStore.isInvalidated()).equals(false);
      check(lock.sessionEpoch).equals(epochAfterNewLogin);
    });

    test('deleteAccount: 実TokenStorage連携で API待機中に sub 無し(email のみ)で別ユーザーが '
        'ログインしても保存済み customUserId を削除してメール照合で新セッションを保護すること', () async {
      final oldJwt = buildJwt(sub: 'user-old', email: 'old@example.com');
      final emailOnlyNewJwt = buildJwt(email: 'new@example.com');
      final storedValues = <String, String?>{};
      final mockSecureStorage = MockFlutterSecureStorage();
      when(() => mockSecureStorage.read(key: any(named: 'key'))).thenAnswer(
        (invocation) async =>
            storedValues[invocation.namedArguments[#key] as String],
      );
      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((invocation) async {
        storedValues[invocation.namedArguments[#key] as String] =
            invocation.namedArguments[#value] as String?;
      });
      when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((
        invocation,
      ) async {
        storedValues.remove(invocation.namedArguments[#key] as String);
      });

      final realStorage = TokenStorage(secureStorage: mockSecureStorage);
      await realStorage.saveTokens(
        accessToken: oldJwt,
        refreshToken: 'refresh-old',
      );
      check(await realStorage.getUserId()).equals('user-old');

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);
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
      final mockLoginResponse = MockResponse();
      when(() => mockLoginResponse.data).thenReturn({
        'access_token': emailOnlyNewJwt,
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

      await repo.login('new@example.com', 'password123');
      check(await realStorage.getUserId()).isNull();

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture).equals(false);

      check(await realStorage.getAccessToken()).equals(emailOnlyNewJwt);
      check(await realStorage.getRefreshToken()).equals('refresh-new');
      check(await realStorage.getUserId()).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);

      // 再起動相当の build() でもメールのみの B のセッションが維持されること
      final restartedContainer = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(restartedContainer.dispose);
      check(
        await restartedContainer.read(authStateProvider.future),
      ).equals(true);
      check(await realStorage.getAccessToken()).equals(emailOnlyNewJwt);
    });

    test('deleteAccount: API待機中に同一アカウントで再ログインが完了しても、無効化状態を維持し '
        '削除完了時・途中再起動時の双方でログイン状態が復元されないこと', () async {
      final initialJwt = buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'initial',
      );
      final reloginJwt = buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'relogin',
      );
      check(reloginJwt).not((it) => it.equals(initialJwt));
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-a',
            )
            ..savedAccessToken = initialJwt
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
        'access_token': reloginJwt,
        'refresh_token': 'refresh-relogin',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockLoginResponse);

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      // 削除完了前に同一アカウントで再ログインしても、無効化レコードは解除されないこと
      await repo.login('a@example.com', 'password123');
      check(lock.sessionEpoch).equals(1);
      check(await invalidationStore.isInvalidated()).equals(true);
      check(await fakeStorage.getAccessToken()).equals(reloginJwt);

      // 削除完了後に新しいトークンと無効化レコードが両方消去されること
      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture).equals(true);

      check(await fakeStorage.getAccessToken()).isNull();
      check(await fakeStorage.getRefreshToken()).isNull();
      check(await fakeStorage.getUserId()).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
      check(lock.sessionEpoch).equals(2);

      // 再度、API待機中に同一アカウントで再ログイン直後にアプリが終了したケースでも
      // 次回起動時に新トークンから誤復元されないこと
      fakeStorage
        ..savedAccessToken = initialJwt
        ..savedRefreshToken = 'refresh-old'
        ..currentUserId = 'user-a';
      final crashDeleteStarted = Completer<void>();
      final crashDeleteNeverCompletes = Completer<Response<void>>();
      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) {
        crashDeleteStarted.complete();
        return crashDeleteNeverCompletes.future;
      });

      unawaited(repo.deleteAccount());
      await crashDeleteStarted.future;
      await repo.login('a@example.com', 'password123');
      check(await invalidationStore.isInvalidated()).equals(true);

      final restartedContainer = createContainer(fakeStorage);
      check(
        await restartedContainer.read(authStateProvider.future),
      ).equals(false);
      check(await fakeStorage.getAccessToken()).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
    });

    test('deleteAccount: API待機中に同一アカウントで再ログイン後、削除完了時のトークン消去にも '
        '失敗した場合は無効化状態を保持し再起動時に未ログインとなること', () async {
      final clearError = Exception('clear failed');
      final initialJwt = buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'initial',
      );
      final reloginJwt = buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'relogin',
      );
      check(reloginJwt).not((it) => it.equals(initialJwt));
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-a',
              clearError: clearError,
            )
            ..savedAccessToken = initialJwt
            ..savedRefreshToken = 'refresh-old';
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
      final mockLoginResponse = MockResponse();
      when(() => mockLoginResponse.data).thenReturn({
        'access_token': reloginJwt,
        'refresh_token': 'refresh-relogin',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockLoginResponse);

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;
      await repo.login('a@example.com', 'password123');

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      await check(deleteFuture).completes((it) => it.equals(true));

      check(await invalidationStore.isInvalidated()).equals(true);
      check(await fakeStorage.getAccessToken()).equals(reloginJwt);

      final restartedContainer = createContainer(fakeStorage);
      check(
        await restartedContainer.read(authStateProvider.future),
      ).equals(false);
    });

    test('deleteAccount: API待機中にトークンが空（別操作でサインアウト済み）になっていた場合は '
        '余計な世代更新を行わず正常終了すること', () async {
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-old',
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

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      await lock.runSessionTransition(() async {
        await fakeStorage.clear();
        await invalidationStore.clearInvalidated();
      });
      check(lock.sessionEpoch).equals(1);

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      await check(deleteFuture).completes((it) => it.equals(true));
      check(lock.sessionEpoch).equals(1);
    });

    test('deleteAccount: API待機中に accessToken のみ消えて他キーが残っていた場合、 '
        'clear() を再試行して全キーと無効化行を削除すること', () async {
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-old',
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

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      // 部分消去（accessToken のみ消去、refreshToken と customUserId は残留）を模擬
      await lock.runSessionTransition(() async {
        fakeStorage.savedAccessToken = null;
      });

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );

      await check(deleteFuture).completes((it) => it.equals(true));
      check(await fakeStorage.getAccessToken()).isNull();
      check(await fakeStorage.getRefreshToken()).isNull();
      check(await fakeStorage.getUserId()).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
    });

    test('deleteAccount: accessToken/refreshToken が空で customUserId のみ残存時も '
        'clear() を再試行して消去すること', () async {
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-old',
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

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      await lock.runSessionTransition(() async {
        fakeStorage
          ..savedAccessToken = null
          ..savedRefreshToken = null
          ..currentRefreshToken = null;
      });

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );

      await check(deleteFuture).completes((it) => it.equals(true));
      check(await fakeStorage.getUserId()).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
    });

    test('deleteAccount: accessToken/refreshToken/customUserId が空で '
        'customUserEmail のみ残存時も clear() を再試行して消去すること', () async {
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-old',
              currentUserEmail: 'old@example.com',
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

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      await lock.runSessionTransition(() async {
        fakeStorage
          ..savedAccessToken = null
          ..savedRefreshToken = null
          ..currentRefreshToken = null
          ..currentUserId = null;
      });

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );

      await check(deleteFuture).completes((it) => it.equals(true));
      check(await fakeStorage.getUserEmail()).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
    });

    test('deleteAccount: refreshToken/customUserId/customUserEmail が null で '
        'accessToken に空文字のみ残存時も clear() を再試行して消去すること', () async {
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-old',
              currentUserEmail: 'old@example.com',
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

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      await lock.runSessionTransition(() async {
        fakeStorage
          ..savedAccessToken = ''
          ..savedRefreshToken = null
          ..currentRefreshToken = null
          ..currentUserId = null
          ..currentUserEmail = null;
      });

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );

      await check(deleteFuture).completes((it) => it.equals(true));
      check(fakeStorage.savedAccessToken).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
    });

    test('deleteAccount: accessToken 欠落かつ他キー残留時に再試行した clear() も失敗した場合、 '
        '無効化行を保持したまま true を返し再起動時に誤復元しないこと', () async {
      final clearRetryError = Exception('retry clear failed');
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-old',
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

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      await lock.runSessionTransition(() async {
        fakeStorage
          ..savedAccessToken = null
          ..clearError = clearRetryError;
      });

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );

      await check(deleteFuture).completes((it) => it.equals(true));
      check(await fakeStorage.getRefreshToken()).equals('refresh-old');
      check(await fakeStorage.getUserId()).equals('user-old');
      check(await invalidationStore.isInvalidated()).equals(true);
      verify(
        () => mockTalker.handle(
          clearRetryError,
          any<StackTrace?>(),
          'Failed to clear local tokens after account deletion',
        ),
      ).called(1);

      // 次回起動時、ストレージが回復していれば残留キーと無効化行を両方消去すること
      fakeStorage.clearError = null;
      final restarted = createContainer(fakeStorage);
      check(await restarted.read(authStateProvider.future)).equals(false);
      check(await fakeStorage.getRefreshToken()).isNull();
      check(await fakeStorage.getUserId()).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
    });

    test('deleteAccount: 待機中にサインアウト済みとなりトークン読み取りも失敗した場合、 '
        'clear() 再試行が失敗しても無効化行を保持して true を返すこと', () async {
      final clearRetryError = Exception('clear failed on fallback');
      final readError = Exception('access token read failed');
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-old',
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

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      await lock.runSessionTransition(() async {
        lock.recordSignedOutSession();
        fakeStorage
          ..getAccessTokenError = readError
          ..clearError = clearRetryError;
      });

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );

      await check(deleteFuture).completes((it) => it.equals(true));
      check(await invalidationStore.isInvalidated()).equals(true);
      verify(
        () => mockTalker.handle(
          readError,
          any<StackTrace?>(),
          'Failed to read current token while resolving account deletion '
          'outcome',
        ),
      ).called(1);
      verify(
        () => mockTalker.handle(
          clearRetryError,
          any<StackTrace?>(),
          'Failed to clear local tokens after account deletion',
        ),
      ).called(1);
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

      await check(repo.deleteAccount()).completes((it) => it.equals(true));

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
      check(invalidationDbFile().existsSync()).equals(true);
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
      // DB ファイルパスにディレクトリを配置して実際の SQLite 書き込みを失敗させる
      Directory(
        p.join(tempDir.path, CustomAuthInvalidationStore.databaseFileName),
      ).createSync(recursive: true);
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      await check(repo.deleteAccount()).throws<SqliteException>();

      verifyNever(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      );
      check(await fakeStorage.getAccessToken()).equals('access-123');
    });

    test('deleteAccount: 保存先ディレクトリが読み取り専用で SQLite 永続化を確定できない場合、 '
        '削除要求を送らず例外を投げトークンが維持されること', () async {
      final fakeStorage = FakeTokenStorage(initialRefreshToken: 'refresh-123')
        ..savedAccessToken = 'access-123'
        ..savedRefreshToken = 'refresh-123';
      Process.runSync('chmod', ['555', tempDir.path]);
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      await check(repo.deleteAccount()).throws<SqliteException>();

      verifyNever(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      );
      check(await fakeStorage.getAccessToken()).equals('access-123');
      check(await invalidationStore.isInvalidated()).equals(false);
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
      check(invalidationDbFile().existsSync()).equals(true);
      check(await fakeStorage.getAccessToken()).equals('access-123');

      // 削除完了前にプロセス終了し、次回起動した想定で別コンテナを生成
      final restartedContainer = createContainer(fakeStorage);
      final restoredAuthState = await restartedContainer.read(
        authStateProvider.future,
      );

      check(restoredAuthState).equals(false);
      check(await fakeStorage.getAccessToken()).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
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
      check(invalidationDbFile().existsSync()).equals(true);

      // そのまま再試行して成功した場合はトークンとフラグを両方クリアする
      await check(repo.deleteAccount()).completes((it) => it.equals(true));
      check(attempts).equals(2);
      check(await fakeStorage.getAccessToken()).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);

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
        // 削除要求前に書かれた DB を更新できない状態にする
        Process.runSync('chmod', ['444', invalidationDbFile().path]);
        Process.runSync('chmod', ['555', tempDir.path]);
        return Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        );
      });

      await check(repo.deleteAccount()).completes((it) => it.equals(true));

      check(fakeStorage.savedAccessToken).isNull();
      verify(
        () => mockTalker.handle(
          any<SqliteException>(),
          any<StackTrace?>(),
          'Failed to clear invalidated custom auth session flag',
        ),
      ).called(1);

      // 書き込み権限復帰後の別ログインではセッション無効化フラグを確実に解除すること
      Process.runSync('chmod', ['755', tempDir.path]);
      Process.runSync('chmod', ['644', invalidationDbFile().path]);
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
    });

    test('deleteAccount: API待機中に同一アカウントで再ログインした後、削除成功後の '
        'getAccessToken() が失敗しても対象セッションを終了しトークンと無効化レコードを消去すること', () async {
      final initialJwt = buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'initial',
      );
      final reloginJwt = buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'relogin',
      );
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-a',
            )
            ..savedAccessToken = initialJwt
            ..savedRefreshToken = 'refresh-old';
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
      final mockLoginResponse = MockResponse();
      when(() => mockLoginResponse.data).thenReturn({
        'access_token': reloginJwt,
        'refresh_token': 'refresh-relogin',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockLoginResponse);

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      await repo.login('a@example.com', 'password123');
      final readError = Exception('token read failed');
      fakeStorage.getAccessTokenError = readError;

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture).equals(true);

      check(fakeStorage.savedAccessToken).isNull();
      check(fakeStorage.savedRefreshToken).isNull();
      check(fakeStorage.currentUserId).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
      verify(
        () => mockTalker.handle(
          readError,
          any<StackTrace?>(),
          'Failed to read current token while resolving account deletion '
          'outcome',
        ),
      ).called(1);
    });

    test('deleteAccount: API待機中に同一アカウントで再ログインした後、削除成功後の '
        'getUserId() が失敗しても対象セッションを終了しトークンと無効化レコードを消去すること', () async {
      final initialJwt = buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'initial',
      );
      final reloginJwt = buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'relogin',
      );
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-a',
            )
            ..savedAccessToken = initialJwt
            ..savedRefreshToken = 'refresh-old';
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
      final mockLoginResponse = MockResponse();
      when(() => mockLoginResponse.data).thenReturn({
        'access_token': reloginJwt,
        'refresh_token': 'refresh-relogin',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockLoginResponse);

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      await repo.login('a@example.com', 'password123');
      final readError = Exception('userId read failed');
      fakeStorage.getUserIdError = readError;

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture).equals(true);

      check(fakeStorage.savedAccessToken).isNull();
      check(fakeStorage.savedRefreshToken).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
      verify(
        () => mockTalker.handle(
          readError,
          any<StackTrace?>(),
          'Failed to read current token while resolving account deletion '
          'outcome',
        ),
      ).called(1);
    });

    test('deleteAccount: API待機中に別アカウントへ切り替わった後、削除成功後の '
        'getAccessToken() や getUserId() が失敗しても別アカウントのトークンを保持すること', () async {
      final oldJwt = buildJwt(sub: 'user-a', email: 'a@example.com');
      final newJwt = buildJwt(sub: 'user-b', email: 'b@example.com');

      for (final isUserIdFailure in [false, true]) {
        late FakeTokenStorage fakeStorage;
        fakeStorage =
            FakeTokenStorage(
                initialRefreshToken: 'refresh-old',
                currentUserId: 'user-a',
                onSaveTokens: (accessToken, _) async {
                  if (accessToken == newJwt) {
                    fakeStorage.currentUserId = 'user-b';
                  }
                },
              )
              ..savedAccessToken = oldJwt
              ..savedRefreshToken = 'refresh-old';
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
        final mockLoginResponse = MockResponse();
        when(
          () => mockLoginResponse.data,
        ).thenReturn({'access_token': newJwt, 'refresh_token': 'refresh-new'});
        when(
          () => mockApi.post<Map<String, dynamic>>(
            '/auth/login',
            data: any<dynamic>(named: 'data'),
          ),
        ).thenAnswer((_) async => mockLoginResponse);

        final deleteFuture = repo.deleteAccount();
        await deleteStarted.future;

        await repo.login('b@example.com', 'password123');
        final readError = Exception(
          isUserIdFailure ? 'userId read failed' : 'token read failed',
        );
        if (isUserIdFailure) {
          fakeStorage.getUserIdError = readError;
        } else {
          fakeStorage.getAccessTokenError = readError;
        }

        deleteCompleter.complete(
          Response<void>(
            requestOptions: RequestOptions(path: '/auth/account'),
            statusCode: 200,
          ),
        );
        check(await deleteFuture).equals(false);

        check(fakeStorage.savedAccessToken).equals(newJwt);
        check(fakeStorage.savedRefreshToken).equals('refresh-new');
        check(await invalidationStore.isInvalidated()).equals(false);
        verify(
          () => mockTalker.handle(
            readError,
            any<StackTrace?>(),
            'Failed to read current token while resolving account deletion '
            'outcome',
          ),
        ).called(1);
      }
    });

    test('deleteAccount: 退会待機中にログアウトして同一アカウントで再ログインし、 '
        '完了時のトークン消去に失敗しても無効化レコードが残り再起動時に復元されないこと', () async {
      final initialJwt = buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'initial',
      );
      final reloginJwt = buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'relogin',
      );
      final clearError = Exception('clear failed after logout and relogin');
      late FakeTokenStorage fakeStorage;
      fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-a',
              onSaveTokens: (accessToken, _) async {
                if (accessToken == reloginJwt) {
                  fakeStorage.currentUserId = 'user-a';
                }
              },
            )
            ..savedAccessToken = initialJwt
            ..savedRefreshToken = 'refresh-old';
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
      final mockLoginResponse = MockResponse();
      when(() => mockLoginResponse.data).thenReturn({
        'access_token': reloginJwt,
        'refresh_token': 'refresh-relogin',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => mockLoginResponse);

      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      final deleteFuture = notifier.deleteAccount();
      await deleteStarted.future;

      // 退会進行中にログアウトしても、進行中の無効化レコードが削除されないこと
      await notifier.logout();
      check(container.read(authStateProvider).value).equals(false);
      final entriesAfterLogout = await invalidationStore
          .getInvalidationEntries();
      check(entriesAfterLogout).length.equals(1);
      check(entriesAfterLogout.single.targetUserId).equals('user-a');

      // そのまま同じアカウントで再ログインしても無効化レコードは保持されること
      check(await repo.login('a@example.com', 'password123')).equals(true);
      check(await invalidationStore.isInvalidated()).equals(true);

      // 削除完了時にトークン消去が失敗してもレコードが残るため、再起動時は未ログインになること
      fakeStorage.clearError = clearError;
      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture).equals(true);
      check(fakeStorage.savedAccessToken).equals(reloginJwt);
      check(await invalidationStore.isInvalidated()).equals(true);

      fakeStorage.clearError = null;
      final restartedContainer = createContainer(fakeStorage);
      check(
        await restartedContainer.read(authStateProvider.future),
      ).equals(false);
      check(fakeStorage.savedAccessToken).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
    });

    test('deleteAccount: 削除対象が sub のみ(email なし)のとき、待機中の識別不能な再ログインを確定させず '
        '削除完了時にトークン消去と true 返却を行うこと', () async {
      final subOnlyJwt = buildJwt(sub: 'user-a');
      final unidentifiableJwt = buildJwt(jti: 'opaque-relogin');
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-a',
            )
            ..savedAccessToken = subOnlyJwt
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
        'access_token': unidentifiableJwt,
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

      // target に email が無く candidate にも sub が無いため照合不能 (AccountMatch.unknown)
      check(await repo.login('a@example.com', 'password123')).equals(false);
      check(fakeStorage.savedAccessToken).equals(subOnlyJwt);
      check(lock.sessionEpoch).equals(0);
      check(await invalidationStore.isInvalidated()).equals(true);

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture).equals(true);
      check(fakeStorage.savedAccessToken).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
    });

    test('deleteAccount: 削除完了時に現在トークンの照合結果が unknown の場合は '
        '別アカウント扱いせず無効化レコードを保持し再起動時に誤復元しないこと', () async {
      final subOnlyJwt = buildJwt(sub: 'user-a');
      final opaqueJwt = buildJwt(jti: 'unknown-token');
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-old',
              currentUserId: 'user-a',
            )
            ..savedAccessToken = subOnlyJwt
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

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      // ロック遷移の直接呼び出し等でストレージが識別不能トークンに差し替わった場合を模擬
      await lock.runSessionTransition(() async {
        await fakeStorage.saveTokens(
          accessToken: opaqueJwt,
          refreshToken: 'refresh-opaque',
        );
        fakeStorage.currentUserId = null;
        lock.recordAuthenticatedSession();
      });

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture).equals(false);

      // AccountMatch.unknown のため無効化レコードを削除せず保持すること
      check(await invalidationStore.isInvalidated()).equals(true);
      check(fakeStorage.savedAccessToken).equals(opaqueJwt);

      // 再起動時は識別不能レコードとみなして残留トークンを消去し false にすること
      final restartedContainer = createContainer(fakeStorage);
      check(
        await restartedContainer.read(authStateProvider.future),
      ).equals(false);
      check(fakeStorage.savedAccessToken).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
    });

    test('deleteAccount: 同一アカウントの退会を 2 件並行開始した場合、 '
        '1 件目完了後も 2 件目の無効化レコードが残り、再ログインと 2 件目消去失敗時も再起動復元しないこと', () async {
      final tokenA1 = buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'delete-1',
      );
      final tokenA2 = buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'delete-2',
      );
      final tokenA3 = buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'relogin',
      );
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-a',
              currentUserId: 'user-a',
            )
            ..savedAccessToken = tokenA1
            ..savedRefreshToken = 'refresh-a';
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      final deleteStarted1 = Completer<void>();
      final deleteCompleter1 = Completer<Response<void>>();
      final deleteStarted2 = Completer<void>();
      final deleteCompleter2 = Completer<Response<void>>();
      var deleteCalls = 0;
      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) {
        deleteCalls++;
        if (deleteCalls == 1) {
          deleteStarted1.complete();
          return deleteCompleter1.future;
        }
        deleteStarted2.complete();
        return deleteCompleter2.future;
      });

      final deleteFuture1 = repo.deleteAccount();
      await deleteStarted1.future;

      // 1 件目待機中に再ログインし、2 件目の退会も開始する
      final loginResponse1 = MockResponse();
      when(
        () => loginResponse1.data,
      ).thenReturn({'access_token': tokenA2, 'refresh_token': 'refresh-a2'});
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => loginResponse1);
      check(await repo.login('a@example.com', 'password123')).equals(true);

      final deleteFuture2 = repo.deleteAccount();
      await deleteStarted2.future;
      check(await invalidationStore.getInvalidationEntries()).length.equals(2);

      // 1 件目完了しても 2 件目が進行中のため A の無効化レコードは残ること
      deleteCompleter1.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture1).equals(true);
      check(await invalidationStore.getInvalidationEntries()).length.equals(1);

      // 1 件目完了後に再び A が再ログインし、2 件目完了時のトークン消去に失敗してもレコードが残ること
      final loginResponse2 = MockResponse();
      when(
        () => loginResponse2.data,
      ).thenReturn({'access_token': tokenA3, 'refresh_token': 'refresh-a3'});
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => loginResponse2);
      check(await repo.login('a@example.com', 'password123')).equals(true);

      fakeStorage.clearError = Exception('clear error on second delete');
      deleteCompleter2.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture2).equals(true);
      check(fakeStorage.savedAccessToken).equals(tokenA3);
      check(await invalidationStore.isInvalidated()).equals(true);

      // 再起動時に A が復元されないこと
      fakeStorage.clearError = null;
      final restartedContainer = createContainer(fakeStorage);
      check(
        await restartedContainer.read(authStateProvider.future),
      ).equals(false);
      check(fakeStorage.savedAccessToken).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
    });

    test('deleteAccount: 削除対象に email があり待機中の同一アカウント再ログインが '
        'sub/email なしトークンを返しても入力メールを補完して同一判定(true)し消去すること', () async {
      final tokenA = buildJwt(sub: 'user-a', email: 'a@example.com');
      final opaqueReloginA = buildJwt(jti: 'opaque-relogin-a');
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-a',
              currentUserId: 'user-a',
            )
            ..savedAccessToken = tokenA
            ..savedRefreshToken = 'refresh-a';
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
      final loginResponse = MockResponse();
      when(() => loginResponse.data).thenReturn({
        'access_token': opaqueReloginA,
        'refresh_token': 'refresh-relogin-a',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => loginResponse);

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      fakeStorage.currentUserId = null;
      check(await repo.login('a@example.com', 'password123')).equals(true);
      check(fakeStorage.savedAccessToken).equals(opaqueReloginA);
      check(await invalidationStore.isInvalidated()).equals(true);

      // さらにリフレッシュでクレームなし新トークンへ更新されても入力メールを引き継いで消去できること
      final refreshResponse = MockResponse();
      final opaqueRefreshedA = buildJwt(jti: 'opaque-refreshed-a');
      when(
        () => refreshResponse.data,
      ).thenReturn({'access_token': opaqueRefreshedA});
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => refreshResponse);
      check(await repo.refreshToken(null)).equals(true);

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture).equals(true);
      check(fakeStorage.savedAccessToken).isNull();
      check(fakeStorage.savedRefreshToken).isNull();
      check(await invalidationStore.isInvalidated()).equals(false);
    });

    test('deleteAccount: 削除待機中の別アカウントログインが sub/email なしトークンを返しても '
        '入力メールで別アカウント判定(false)しトークン保護と古い無効化解除を行うこと', () async {
      final tokenA = buildJwt(sub: 'user-a', email: 'a@example.com');
      final opaqueLoginB = buildJwt(jti: 'opaque-login-b');
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-a',
              currentUserId: 'user-a',
            )
            ..savedAccessToken = tokenA
            ..savedRefreshToken = 'refresh-a';
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
      final loginResponse = MockResponse();
      when(() => loginResponse.data).thenReturn({
        'access_token': opaqueLoginB,
        'refresh_token': 'refresh-b',
      });
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => loginResponse);

      final deleteFuture = repo.deleteAccount();
      await deleteStarted.future;

      fakeStorage.currentUserId = null;
      check(await repo.login('b@example.com', 'password123')).equals(true);
      check(fakeStorage.savedAccessToken).equals(opaqueLoginB);
      check(await invalidationStore.isInvalidated()).equals(true);

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture).equals(false);
      check(fakeStorage.savedAccessToken).equals(opaqueLoginB);
      check(fakeStorage.savedRefreshToken).equals('refresh-b');
      check(await invalidationStore.isInvalidated()).equals(false);
    });

    test('deleteAccount: サーバーが削除未実行を明示した失敗時は自身の無効化行のみを解除し、 '
        'ロック終了後に元の例外を再スローすること', () async {
      final jwtA = buildJwt(sub: 'user-a', email: 'a@example.com');
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-a',
              currentUserId: 'user-a',
            )
            ..savedAccessToken = jwtA
            ..savedRefreshToken = 'refresh-a';
      final spyStore = _SpyCustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          customAuthInvalidationStoreProvider.overrideWithValue(spyStore),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);
      final repo = container.read(authRepositoryProvider);
      final lock = container.read(authSessionLockProvider);

      Future<List<int>> readInvalidationRowIds() async {
        final executor = NativeDatabase(
          invalidationDbFile(),
          enableMigrations: false,
        );
        await executor.ensureOpen(const _TestQueryExecutorUser());
        try {
          final rows = await executor.runSelect(
            'SELECT id FROM custom_auth_invalidation_entries ORDER BY id ASC;',
            const [],
          );
          return [
            for (final row in rows)
              switch (row['id']) {
                final int id => id,
                final other => fail('Unexpected row id: $other'),
              },
          ];
        } finally {
          await executor.close();
        }
      }

      // 先行・別の退会要求が所有する無効化行が存在していても保持されるべき
      final precedingEntryId = await spyStore.markInvalidated(
        targetUserId: 'user-a',
        targetEmail: 'a@example.com',
      );

      final errors = <Exception>[
        const AppException.unauthenticated(),
        const AppException.badRequest(statusCode: 400),
        const ReauthException.requiresRecentLogin(),
        DioException(
          requestOptions: RequestOptions(path: '/auth/account'),
          response: Response<void>(
            requestOptions: RequestOptions(path: '/auth/account'),
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        ),
      ];

      for (final error in errors) {
        final markCountBefore = spyStore.markedEntryIds.length;
        spyStore.clearedEntryIds.clear();
        when(
          () => mockApi.delete<void>(
            '/auth/account',
            options: any<Options?>(named: 'options'),
          ),
        ).thenAnswer((_) async => throw error);

        await check(
          repo.deleteAccount(),
        ).throws<Object>((it) => it.equals(error));
        check(lock.isDeletionInProgress).equals(false);
        check(
          lock.hasOtherActiveDeletion(
            entryId: -1,
            userId: 'user-a',
            email: 'a@example.com',
          ),
        ).equals(false);
        check(await fakeStorage.getAccessToken()).equals(jwtA);
        check(spyStore.markedEntryIds.length).equals(markCountBefore + 1);
        final currentEntryId = spyStore.markedEntryIds.last;
        check(currentEntryId).not((it) => it.equals(precedingEntryId));
        check(spyStore.clearedEntryIds).deepEquals([currentEntryId]);
        // 先行していた行 ID のみが残り、今回の行 ID は削除されていること
        check(await readInvalidationRowIds()).deepEquals([precedingEntryId]);
      }

      // 削除成否不明の失敗群（408 や通信・解析・キャンセル・不明エラー）は無効化行を保持すること
      final uncertainErrors = <Exception>[
        const AppException.badRequest(statusCode: 408),
        const AppException.network(),
        const AppException.dataParse(),
        const AppException.database(),
        const AppException.cancel(),
        const AppException.unknown(),
      ];

      final expectedRemainingIds = <int>[precedingEntryId];
      for (final error in uncertainErrors) {
        final markCountBefore = spyStore.markedEntryIds.length;
        spyStore.clearedEntryIds.clear();
        when(
          () => mockApi.delete<void>(
            '/auth/account',
            options: any<Options?>(named: 'options'),
          ),
        ).thenAnswer((_) async => throw error);

        await check(
          repo.deleteAccount(),
        ).throws<Exception>((it) => it.equals(error));
        check(spyStore.markedEntryIds.length).equals(markCountBefore + 1);
        expectedRemainingIds.add(spyStore.markedEntryIds.last);
        check(spyStore.clearedEntryIds).isEmpty();
        check(lock.isDeletionInProgress).equals(false);
        check(await readInvalidationRowIds()).deepEquals(expectedRemainingIds);
      }
    });

    test('deleteAccount: 単独退会で削除未実行の失敗後に再起動しても、無効化行が解除され '
        '通常セッションを維持すること', () async {
      final jwtA = buildJwt(sub: 'user-a', email: 'a@example.com');
      final fakeStorage =
          FakeTokenStorage(
              initialRefreshToken: 'refresh-a',
              currentUserId: 'user-a',
            )
            ..savedAccessToken = jwtA
            ..savedRefreshToken = 'refresh-a';
      final container = createContainer(fakeStorage);
      final repo = container.read(authRepositoryProvider);

      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) async => throw const AppException.unauthorized());

      await check(repo.deleteAccount()).throws<UnauthorizedException>();
      check(await invalidationStore.isInvalidated()).equals(false);
      check(await fakeStorage.getAccessToken()).equals(jwtA);

      final restartedContainer = createContainer(fakeStorage);
      check(
        await restartedContainer.read(authStateProvider.future),
      ).equals(true);
      check(await fakeStorage.getAccessToken()).equals(jwtA);
    });

    test('login / refreshToken / deleteAccount: クレーム無しトークンでも入力メールを '
        '実TokenStorageへ永続化・引き継ぎし、再起動後にメール照合で削除実行できること', () async {
      final store = <String, String>{};
      final mockSecureStorage = MockFlutterSecureStorage();
      when(
        () => mockSecureStorage.read(key: any(named: 'key')),
      ).thenAnswer((inv) async => store[extractStorageKey('read', inv)]);
      when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((
        inv,
      ) async {
        store.remove(extractStorageKey('delete', inv));
      });
      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((inv) async {
        final (:key, :value) = switch (inv.namedArguments) {
          {#key: final String key, #value: final String? value} => (
            key: key,
            value: value,
          ),
          _ => fail('Unexpected write arguments: ${inv.namedArguments}'),
        };
        if (value == null) {
          store.remove(key);
        } else {
          store[key] = value;
        }
      });

      final realStorage = TokenStorage(secureStorage: mockSecureStorage);
      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);
      final repo = container.read(authRepositoryProvider);

      final opaqueLogin = buildJwt(jti: 'opaque-login');
      final opaqueRefresh = buildJwt(jti: 'opaque-refresh');
      final loginResponse = MockResponse();
      when(
        () => loginResponse.data,
      ).thenReturn({'access_token': opaqueLogin, 'refresh_token': 'refresh-1'});
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => loginResponse);

      check(await repo.login('user@example.com', 'password123')).equals(true);
      check(
        store[SecureStorageKeys.customUserEmail],
      ).equals('user@example.com');
      check(await repo.getCurrentEmail()).equals('user@example.com');

      // リフレッシュ後も入力メールが永続化ストレージに維持されること
      final refreshResponse = MockResponse();
      when(
        () => refreshResponse.data,
      ).thenReturn({'access_token': opaqueRefresh});
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async => refreshResponse);
      check(await repo.refreshToken(null)).equals(true);
      check(
        store[SecureStorageKeys.customUserEmail],
      ).equals('user@example.com');

      // 新しい Container（再起動相当、AuthSessionLock は新規）から deleteAccount を開始し、
      // 無効化レコードへ targetEmail が記録されること
      final restarted = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(restarted.dispose);
      final restartedRepo = restarted.read(authRepositoryProvider);
      check(await restartedRepo.getCurrentEmail()).equals('user@example.com');

      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenThrow(const AppException.network());

      await check(restartedRepo.deleteAccount()).throws<NetworkException>();
      final entries = await invalidationStore.getInvalidationEntries();
      check(entries).length.equals(1);
      check(entries.single.targetUserId).isNull();
      check(entries.single.targetEmail).equals('user@example.com');

      // 不明障害後の再起動でも、永続化された customUserEmail により同一アカウントと判定し全消去すること
      final recoveryContainer = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(recoveryContainer.dispose);
      check(
        await recoveryContainer.read(authStateProvider.future),
      ).equals(false);
      check(store).isEmpty();
      check(await invalidationStore.isInvalidated()).equals(false);
    });

    test('起動時照合: 無効化情報のメールが a@example.com でクレーム無しトークンに '
        'b@example.com が保存されている場合、true を返し B の資格情報を保持すること', () async {
      final store = <String, String>{};
      final mockSecureStorage = MockFlutterSecureStorage();
      when(
        () => mockSecureStorage.read(key: any(named: 'key')),
      ).thenAnswer((inv) async => store[extractStorageKey('read', inv)]);
      when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((
        inv,
      ) async {
        store.remove(extractStorageKey('delete', inv));
      });
      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((inv) async {
        final (:key, :value) = switch (inv.namedArguments) {
          {#key: final String key, #value: final String? value} => (
            key: key,
            value: value,
          ),
          _ => fail('Unexpected write arguments: ${inv.namedArguments}'),
        };
        if (value == null) {
          store.remove(key);
        } else {
          store[key] = value;
        }
      });

      final realStorage = TokenStorage(secureStorage: mockSecureStorage);
      final opaqueB = buildJwt(jti: 'opaque-b');
      await invalidationStore.markInvalidated(targetEmail: 'a@example.com');
      await realStorage.saveTokens(
        accessToken: opaqueB,
        refreshToken: 'refresh-b',
        email: 'b@example.com',
      );

      final startupContainer = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(startupContainer.dispose);

      check(await startupContainer.read(authStateProvider.future)).equals(true);
      check(store[SecureStorageKeys.accessToken]).equals(opaqueB);
      check(store[SecureStorageKeys.refreshToken]).equals('refresh-b');
      check(store[SecureStorageKeys.customUserEmail]).equals('b@example.com');
      check(store.containsKey(SecureStorageKeys.customUserId)).equals(false);
      check(await invalidationStore.isInvalidated()).equals(false);
    });
  });
}
