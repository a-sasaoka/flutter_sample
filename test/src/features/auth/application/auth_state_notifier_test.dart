import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sample/src/app/constants/storage_keys.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/utils/jwt_utils.dart';
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

class MockAuthRepository extends Mock implements AuthRepository {}

class MockApiClient extends Mock implements ApiClient {}

class MockTalker extends Mock implements Talker {}

class MockCustomAuthInvalidationStore extends Mock
    implements CustomAuthInvalidationStore {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

String _buildJwt({String? sub, String? email, String? jti}) {
  final header = base64Url.encode(
    utf8.encode(jsonEncode({'alg': 'none', 'typ': 'JWT'})),
  );
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode(<String, Object?>{'sub': ?sub, 'email': ?email, 'jti': ?jti}),
    ),
  );
  return '$header.$payload.sig';
}

class FakeTokenStorage extends Mock implements TokenStorage {
  FakeTokenStorage({
    this.mockAccessToken,
    this.mockAccessTokenFuture,
    this.currentUserId,
    this.currentUserEmail,
    this.shouldThrowOnSave = false,
    this.shouldThrowOnClear = false,
    this.onSaveTokens,
  });

  String? mockAccessToken;
  String? mockRefreshToken;
  final Future<String?>? mockAccessTokenFuture;
  String? currentUserId;
  String? currentUserEmail;
  final bool shouldThrowOnSave;
  bool shouldThrowOnClear;
  Exception? getAccessTokenError;
  Exception? getUserIdError;
  Exception? getUserEmailError;
  Future<void> Function(String accessToken, String refreshToken)? onSaveTokens;

  // 呼び出し確認用のフラグ
  bool isSaveTokensCalled = false;
  bool isClearCalled = false;

  static String? _normalizeIdentity(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<String?> getAccessToken() async {
    if (getAccessTokenError != null) {
      throw getAccessTokenError!;
    }
    return mockAccessTokenFuture != null
        ? await mockAccessTokenFuture!
        : mockAccessToken;
  }

  @override
  Future<String?> getRefreshToken() async => mockRefreshToken;

  @override
  Future<String?> getUserId() async {
    if (getUserIdError != null) {
      throw getUserIdError!;
    }
    if (currentUserId != null) {
      return currentUserId;
    }
    final token = await getAccessToken();
    return token != null ? JwtUtils.getUserId(token) : null;
  }

  @override
  Future<String?> getUserEmail() async {
    if (getUserEmailError != null) {
      throw getUserEmailError!;
    }
    final normalizedEmail = _normalizeIdentity(currentUserEmail);
    if (normalizedEmail != null) {
      return normalizedEmail;
    }
    final token = await getAccessToken();
    return token != null ? _normalizeIdentity(JwtUtils.getEmail(token)) : null;
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
    String? email,
    bool preserveExistingOnFailure = false,
  }) async {
    isSaveTokensCalled = true;
    if (shouldThrowOnSave) {
      throw Exception('Failed to save tokens');
    }
    mockAccessToken = accessToken;
    mockRefreshToken = refreshToken;
    currentUserId =
        _normalizeIdentity(JwtUtils.getUserId(accessToken)) ??
        _normalizeIdentity(userId);
    currentUserEmail =
        _normalizeIdentity(JwtUtils.getEmail(accessToken)) ??
        _normalizeIdentity(email);
    await onSaveTokens?.call(accessToken, refreshToken);
  }

  @override
  Future<void> clear() async {
    isClearCalled = true;
    if (shouldThrowOnClear) {
      throw Exception('Failed to clear tokens');
    }
    currentUserId = null;
    currentUserEmail = null;
    mockAccessToken = null;
    mockRefreshToken = null;
  }
}

void main() {
  late MockTalker mockTalker;
  late Directory tempDir;

  File invalidationDbFile() =>
      File(p.join(tempDir.path, CustomAuthInvalidationStore.databaseFileName));

  setUpAll(() {
    registerFallbackValue(StackTrace.current);
    registerFallbackValue(Options());
  });

  setUp(() {
    mockTalker = MockTalker();
    tempDir = Directory.systemTemp.createTempSync('auth_state_notifier_test_');
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

  /// テストごとにクリーンな ProviderContainer を作成するヘルパー
  ProviderContainer createContainer({
    FakeTokenStorage? fakeStorage,
    MockAuthRepository? mockAuthRepository,
    CustomAuthInvalidationStore? mockInvalidationStore,
  }) {
    final storage = fakeStorage ?? FakeTokenStorage();
    final container = ProviderContainer(
      overrides: [
        // tokenStorageProvider を Fake クラスに差し替える
        tokenStorageProvider.overrideWith((ref) => storage),
        appSupportDirectoryReaderProvider.overrideWithValue(
          () async => tempDir,
        ),
        loggerProvider.overrideWithValue(mockTalker),
        // authRepositoryProvider を Mock クラスに差し替える
        if (mockAuthRepository != null)
          authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
        if (mockInvalidationStore != null)
          customAuthInvalidationStoreProvider.overrideWithValue(
            mockInvalidationStore,
          ),
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

  group('AuthStateNotifier (build)', () {
    test('初期化: トークンが存在する場合、state が true になること', () async {
      // Arrange: 有効なトークンを返す Fake を作成
      final fakeStorage = FakeTokenStorage(mockAccessToken: 'valid_token');
      final container = createContainer(fakeStorage: fakeStorage);

      // Act
      final authState = await container.read(authStateProvider.future);

      // Assert
      check(authState).equals(true);
    });

    test('初期化: トークンがない場合、state が false になること', () async {
      // Arrange: トークンがない Fake を作成
      final fakeStorage = FakeTokenStorage();
      final container = createContainer(fakeStorage: fakeStorage);

      // Act
      final authState = await container.read(authStateProvider.future);

      // Assert
      check(authState).equals(false);
    });

    test('初期化: セッション無効化フラグが立っている場合、残留トークンがあっても未ログイン(false)となり '
        '再消去に成功すればフラグを解除すること', () async {
      final fakeStorage = FakeTokenStorage(mockAccessToken: 'stale_token');
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated();
      final container = createContainer(fakeStorage: fakeStorage);

      final authState = await container.read(authStateProvider.future);

      check(authState).equals(false);
      check(fakeStorage.isClearCalled).equals(true);
      check(fakeStorage.mockAccessToken).isNull();
      check(await store.isInvalidated()).equals(false);
      check(invalidationDbFile().existsSync()).equals(true);
    });

    test('初期化: セッション無効化フラグが立っており再消去にも失敗した場合、 '
        'エラーを記録してフラグを保持したまま未ログイン(false)となること', () async {
      final fakeStorage = FakeTokenStorage(
        mockAccessToken: 'stale_token',
        shouldThrowOnClear: true,
      );
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated();
      final container = createContainer(fakeStorage: fakeStorage);

      final authState = await container.read(authStateProvider.future);

      check(authState).equals(false);
      check(fakeStorage.isClearCalled).equals(true);
      check(await store.isInvalidated()).equals(true);
      check(invalidationDbFile().existsSync()).equals(true);
      verify(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace?>(),
          'Failed to clear invalidated custom auth tokens on startup',
        ),
      ).called(1);
    });

    test('初期化: 無効化レコードが別アカウント向けで別ユーザーのトークンが存在する場合は '
        '新トークンを維持し古い無効化レコードのみ削除して true を返すこと', () async {
      final userBToken = _buildJwt(sub: 'user-b', email: 'b@example.com');
      final fakeStorage = FakeTokenStorage(
        mockAccessToken: userBToken,
        currentUserId: 'user-b',
      );
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated(
        targetUserId: 'user-a',
        targetEmail: 'a@example.com',
      );
      final container = createContainer(fakeStorage: fakeStorage);

      final authState = await container.read(authStateProvider.future);

      check(authState).equals(true);
      check(fakeStorage.isClearCalled).equals(false);
      check(fakeStorage.mockAccessToken).equals(userBToken);
      check(await store.isInvalidated()).equals(false);
    });

    test('初期化: 別アカウント維持時に古い無効化レコード削除だけ失敗しても、 '
        'エラーを記録してログイン状態(true)を維持すること', () async {
      final userBToken = _buildJwt(sub: 'user-b', email: 'b@example.com');
      final fakeStorage = FakeTokenStorage(
        mockAccessToken: userBToken,
        currentUserId: 'user-b',
      );
      final mockStore = MockCustomAuthInvalidationStore();
      final clearError = Exception('Failed to clear invalidation record');
      when(mockStore.isLoginPending).thenAnswer((_) async => false);
      when(mockStore.isLogoutPending).thenAnswer((_) async => false);
      when(mockStore.getInvalidationEntries).thenAnswer(
        (_) async => [(targetUserId: 'user-a', targetEmail: 'a@example.com')],
      );
      when(
        mockStore.clearInvalidated,
      ).thenAnswer((_) async => throw clearError);

      final container = createContainer(
        fakeStorage: fakeStorage,
        mockInvalidationStore: mockStore,
      );
      final authState = await container.read(authStateProvider.future);

      check(authState).equals(true);
      check(fakeStorage.isClearCalled).equals(false);
      check(fakeStorage.mockAccessToken).equals(userBToken);
      verify(mockStore.getInvalidationEntries).called(1);
      verify(mockStore.clearInvalidated).called(1);
      verify(
        () => mockTalker.handle(
          clearError,
          any<StackTrace?>(),
          'Failed to clear obsolete custom auth invalidation flag on startup',
        ),
      ).called(1);
    });

    test('初期化: 退会無効化レコードが存在し保存済み資格情報に識別情報が無い場合は '
        '復元せず全キーを消去して false を返すこと', () async {
      final storedValues = <String, String>{
        SecureStorageKeys.accessToken: 'legacy-opaque-token',
        SecureStorageKeys.refreshToken: 'legacy-refresh-token',
      };
      final mockSecureStorage = MockFlutterSecureStorage();
      when(() => mockSecureStorage.read(key: any(named: 'key'))).thenAnswer(
        (inv) async => storedValues[inv.namedArguments[#key] as String],
      );
      when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((
        inv,
      ) async {
        storedValues.remove(inv.namedArguments[#key] as String);
      });
      final realStorage = TokenStorage(secureStorage: mockSecureStorage);
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated(
        targetUserId: 'user-a',
        targetEmail: 'a@example.com',
      );

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      check(await container.read(authStateProvider.future)).equals(false);
      check(storedValues).isEmpty();
      check(await store.isInvalidated()).equals(false);
    });

    test('初期化: 無効化レコードが無い場合も保存済み customUserId と customUserEmail を '
        'AuthSessionLock へ復元すること', () async {
      final storedValues = <String, String>{
        SecureStorageKeys.accessToken: 'opaque-token',
        SecureStorageKeys.refreshToken: 'opaque-refresh',
        SecureStorageKeys.customUserId: 'user-a',
        SecureStorageKeys.customUserEmail: 'a@example.com',
      };
      final mockSecureStorage = MockFlutterSecureStorage();
      when(() => mockSecureStorage.read(key: any(named: 'key'))).thenAnswer(
        (inv) async => storedValues[inv.namedArguments[#key] as String],
      );
      final realStorage = TokenStorage(secureStorage: mockSecureStorage);

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      check(await container.read(authStateProvider.future)).equals(true);
      check(container.read(authSessionLockProvider).currentSession).equals(
        const TrackedAuthSession.authenticated(
          accessToken: 'opaque-token',
          userId: 'user-a',
          email: 'a@example.com',
        ),
      );
    });

    test('初期化: JWT の sub が無効化レコードと一致する場合は getUserEmail() が失敗しても '
        '読まずにトークンと無効化レコードを消去して false を返すこと', () async {
      final tokenA = _buildJwt(sub: 'user-a');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenA)
        ..getUserIdError = Exception('userId read should not block sub match')
        ..getUserEmailError = Exception('email read failed');
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated(
        targetUserId: 'user-a',
        targetEmail: 'a@example.com',
      );
      final container = createContainer(fakeStorage: fakeStorage);

      check(await container.read(authStateProvider.future)).equals(false);
      check(fakeStorage.isClearCalled).equals(true);
      check(fakeStorage.mockAccessToken).isNull();
      check(await store.isInvalidated()).equals(false);
      verifyNever(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace?>(),
          'Failed to read user email during startup invalidation check',
        ),
      );
    });

    test('初期化: JWT が email クレームのみで無効化メールと一致する場合は getUserEmail() が失敗しても '
        '読まずに消去すること', () async {
      final tokenEmailOnly = _buildJwt(email: 'a@example.com');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenEmailOnly)
        ..getUserIdError = Exception('userId read should not block email match')
        ..getUserEmailError = Exception('email read failed');
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated(targetEmail: 'a@example.com');
      final container = createContainer(fakeStorage: fakeStorage);

      check(await container.read(authStateProvider.future)).equals(false);
      check(fakeStorage.isClearCalled).equals(true);
      check(fakeStorage.mockAccessToken).isNull();
      check(await store.isInvalidated()).equals(false);
    });

    test('初期化: 無効化行がすべてメールのみで JWT の email が別アカウントの場合は '
        'getUserId() に失敗しても Talker に記録して復元を続けること', () async {
      final tokenBEmailOnly = _buildJwt(email: 'b@example.com');
      final readError = Exception('userId read failed during restore');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenBEmailOnly)
        ..getUserIdError = readError;
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated(targetEmail: 'a@example.com');
      final container = createContainer(fakeStorage: fakeStorage);

      check(await container.read(authStateProvider.future)).equals(true);
      check(fakeStorage.isClearCalled).equals(false);
      check(await store.isInvalidated()).equals(false);
      check(container.read(authSessionLockProvider).currentSession).equals(
        TrackedAuthSession.authenticated(
          accessToken: tokenBEmailOnly,
          email: 'b@example.com',
        ),
      );
      verify(
        () => mockTalker.handle(
          readError,
          any<StackTrace?>(),
          'Failed to read user id while restoring session on startup',
        ),
      ).called(1);
    });

    test('初期化: 識別不能なメールなし無効化行と JWT のメールのみで照合する場合、 '
        'getUserId() を読まずに安全側で消去すること', () async {
      final tokenBEmailOnly = _buildJwt(email: 'b@example.com');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenBEmailOnly)
        ..getUserIdError = Exception('userId read should not block clear');
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated();
      final container = createContainer(fakeStorage: fakeStorage);

      check(await container.read(authStateProvider.future)).equals(false);
      check(fakeStorage.isClearCalled).equals(true);
      check(fakeStorage.mockAccessToken).isNull();
      check(await store.isInvalidated()).equals(false);
    });

    test('初期化: 無効化行が ID を持つ場合は JWT の email が異なっても ID 優先で照合し '
        'getUserId() 失敗時は復元せず無効化行を保持すること', () async {
      final tokenBEmailOnly = _buildJwt(email: 'b@example.com');
      final readError = Exception('userId read failed');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenBEmailOnly)
        ..getUserIdError = readError;
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated(
        targetUserId: 'user-a',
        targetEmail: 'a@example.com',
      );
      final container = createContainer(fakeStorage: fakeStorage);

      check(await container.read(authStateProvider.future)).equals(false);
      check(fakeStorage.isClearCalled).equals(false);
      check(await store.isInvalidated()).equals(true);
      verify(
        () => mockTalker.handle(
          readError,
          any<StackTrace?>(),
          'Failed to read user id during startup invalidation check',
        ),
      ).called(1);
    });

    test('初期化: 無効化行が ID を持ち別ユーザーの customUserId がある場合は '
        'JWT の email が同一でも ID 優先で別アカウントとして復元すること', () async {
      final tokenReusedEmail = _buildJwt(email: 'a@example.com');
      final fakeStorage = FakeTokenStorage(
        mockAccessToken: tokenReusedEmail,
        currentUserId: 'user-b',
      );
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated(
        targetUserId: 'user-a',
        targetEmail: 'a@example.com',
      );
      final container = createContainer(fakeStorage: fakeStorage);

      check(await container.read(authStateProvider.future)).equals(true);
      check(fakeStorage.isClearCalled).equals(false);
      check(await store.isInvalidated()).equals(false);
      check(container.read(authSessionLockProvider).currentSession).equals(
        TrackedAuthSession.authenticated(
          accessToken: tokenReusedEmail,
          userId: 'user-b',
          email: 'a@example.com',
        ),
      );
    });

    test('初期化: 保存済み customUserId が無効化レコードと一致する場合は getUserEmail() が失敗しても '
        '消去すること', () async {
      final opaqueToken = _buildJwt(jti: 'opaque-a');
      final fakeStorage = FakeTokenStorage(
        mockAccessToken: opaqueToken,
        currentUserId: 'user-a',
      )..getUserEmailError = Exception('email read failed');
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated(
        targetUserId: 'user-a',
        targetEmail: 'a@example.com',
      );
      final container = createContainer(fakeStorage: fakeStorage);

      check(await container.read(authStateProvider.future)).equals(false);
      check(fakeStorage.isClearCalled).equals(true);
      check(await store.isInvalidated()).equals(false);
    });

    test('初期化: メール照合が必要な状態で getUserEmail() に失敗した場合は '
        '無効化レコードを保持したまま未ログイン(false)にし復元しないこと', () async {
      final opaqueToken = _buildJwt(jti: 'opaque-unknown');
      final readError = Exception('secure storage email read failed');
      final fakeStorage = FakeTokenStorage(mockAccessToken: opaqueToken)
        ..getUserEmailError = readError;
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated(targetEmail: 'a@example.com');
      final container = createContainer(fakeStorage: fakeStorage);

      check(await container.read(authStateProvider.future)).equals(false);
      check(fakeStorage.isClearCalled).equals(false);
      check(fakeStorage.mockAccessToken).equals(opaqueToken);
      check(await store.isInvalidated()).equals(true);
      check(
        container.read(authSessionLockProvider).currentSession,
      ).isA<SignedOutTrackedAuthSession>();
      verify(
        () => mockTalker.handle(
          readError,
          any<StackTrace?>(),
          'Failed to read user email during startup invalidation check',
        ),
      ).called(1);
    });

    test('初期化: 識別情報照合が必要な状態で getUserId() に失敗した場合は '
        '無効化レコードを保持したまま未ログイン(false)にし復元しないこと', () async {
      final opaqueToken = _buildJwt(jti: 'opaque-unknown');
      final readError = Exception('secure storage userId read failed');
      final fakeStorage = FakeTokenStorage(mockAccessToken: opaqueToken)
        ..getUserIdError = readError;
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated(
        targetUserId: 'user-a',
        targetEmail: 'a@example.com',
      );
      final container = createContainer(fakeStorage: fakeStorage);

      check(await container.read(authStateProvider.future)).equals(false);
      check(fakeStorage.isClearCalled).equals(false);
      check(await store.isInvalidated()).equals(true);
      verify(
        () => mockTalker.handle(
          readError,
          any<StackTrace?>(),
          'Failed to read user id during startup invalidation check',
        ),
      ).called(1);
    });

    test('初期化: 別アカウントの sub が無効化対象と異なりメール照合不要な場合は '
        'getUserEmail() が失敗してもセッション維持して true を返すこと', () async {
      final tokenB = _buildJwt(sub: 'user-b');
      final readError = Exception('email read failed during restore');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenB)
        ..getUserEmailError = readError;
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated(
        targetUserId: 'user-a',
        targetEmail: 'a@example.com',
      );
      final container = createContainer(fakeStorage: fakeStorage);

      check(await container.read(authStateProvider.future)).equals(true);
      check(fakeStorage.isClearCalled).equals(false);
      check(await store.isInvalidated()).equals(false);
      check(container.read(authSessionLockProvider).currentSession).equals(
        TrackedAuthSession.authenticated(accessToken: tokenB, userId: 'user-b'),
      );
      verify(
        () => mockTalker.handle(
          readError,
          any<StackTrace?>(),
          'Failed to read user email while restoring session on startup',
        ),
      ).called(1);
    });

    test('初期化: 無効化レコードが無い状態で getUserEmail() が失敗しても '
        'Talker に記録してメール null・保存済みトークンと ID で true を返すこと', () async {
      final tokenA = _buildJwt(sub: 'user-a');
      final readError = Exception('email read failed on clean startup');
      final fakeStorage = FakeTokenStorage(
        mockAccessToken: tokenA,
        currentUserId: 'user-a',
      )..getUserEmailError = readError;
      final container = createContainer(fakeStorage: fakeStorage);

      check(await container.read(authStateProvider.future)).equals(true);
      check(fakeStorage.isClearCalled).equals(false);
      check(container.read(authSessionLockProvider).currentSession).equals(
        TrackedAuthSession.authenticated(accessToken: tokenA, userId: 'user-a'),
      );
      verify(
        () => mockTalker.handle(
          readError,
          any<StackTrace?>(),
          'Failed to read user email while restoring session on startup',
        ),
      ).called(1);
    });

    test('FakeTokenStorage: 空白のみの email クレーム時は入力メールへフォールバックし '
        'getUserEmail() でも JWT クレームを正規化すること', () async {
      final blankEmailJwt = _buildJwt(email: '   ');
      final validClaimJwt = _buildJwt(email: '  claim@example.com  ');
      final fakeStorage = FakeTokenStorage();

      await fakeStorage.saveTokens(
        accessToken: blankEmailJwt,
        refreshToken: 'refresh-1',
        email: '  input@example.com  ',
      );
      check(fakeStorage.currentUserEmail).equals('input@example.com');
      check(await fakeStorage.getUserEmail()).equals('input@example.com');

      fakeStorage
        ..currentUserEmail = null
        ..mockAccessToken = blankEmailJwt;
      check(await fakeStorage.getUserEmail()).isNull();

      fakeStorage.mockAccessToken = validClaimJwt;
      check(await fakeStorage.getUserEmail()).equals('claim@example.com');
    });
  });

  group('AuthStateNotifier (methods)', () {
    test('login: トークンを保存し、state を true に更新すること', () async {
      // Arrange
      final fakeStorage = FakeTokenStorage();
      final container = createContainer(fakeStorage: fakeStorage);
      final notifier = container.read(authStateProvider.notifier);

      // Act
      await notifier.login('access', 'refresh');

      // Assert
      check(fakeStorage.isSaveTokensCalled).equals(true); // saveTokens が呼ばれたか
      check(
        container.read(authStateProvider).value,
      ).equals(true); // state が true か
    });

    test('login: トークンの保存に失敗した場合、例外がスローされ state が AsyncError になること', () async {
      // Arrange
      final fakeStorage = FakeTokenStorage(shouldThrowOnSave: true);
      final container = createContainer(fakeStorage: fakeStorage);
      final notifier = container.read(authStateProvider.notifier);

      // Act & Assert
      await check(notifier.login('access', 'refresh')).throws<Exception>();

      // Assert
      check(fakeStorage.isSaveTokensCalled).equals(true); // saveTokens が呼ばれたか
      check(fakeStorage.mockAccessToken).isNull();
      check(
        container.read(authStateProvider).hasError,
      ).equals(true); // state が AsyncError か
    });

    test('login: 途中まで保存した後に失敗した場合でもロールバックされ新しい資格情報が残らないこと', () async {
      final partialSaveError = Exception('partial save failed');
      final fakeStorage = FakeTokenStorage(
        onSaveTokens: (_, _) => throw partialSaveError,
      );
      final container = createContainer(fakeStorage: fakeStorage);
      final notifier = container.read(authStateProvider.notifier);

      await check(
        notifier.login('partial-access', 'partial-refresh'),
      ).throws<Exception>((it) => it.equals(partialSaveError));

      check(fakeStorage.isSaveTokensCalled).equals(true);
      check(fakeStorage.isClearCalled).equals(true);
      check(fakeStorage.mockAccessToken).isNull();
      check(container.read(authStateProvider).hasError).equals(true);
      final store = container.read(customAuthInvalidationStoreProvider);
      check(await store.isLoginPending()).equals(false);
    });

    test('login: 部分保存失敗時のロールバック消去にも失敗した場合は '
        '未確定フラグを保持して再起動時もログイン復元せず回復後に再消去すること', () async {
      final partialSaveError = Exception('partial save failed');
      final fakeStorage = FakeTokenStorage(
        shouldThrowOnClear: true,
        onSaveTokens: (_, _) => throw partialSaveError,
      );
      final container = createContainer(fakeStorage: fakeStorage);
      final notifier = container.read(authStateProvider.notifier);

      await check(
        notifier.login('partial-access', 'partial-refresh'),
      ).throws<Exception>((it) => it.equals(partialSaveError));

      check(fakeStorage.mockAccessToken).equals('partial-access');
      final store = container.read(customAuthInvalidationStoreProvider);
      check(await store.isLoginPending()).equals(true);

      // ストレージ障害が継続した状態で再起動しても未ログインになりフラグは維持されること
      final failedRestartContainer = createContainer(fakeStorage: fakeStorage);
      check(
        await failedRestartContainer.read(authStateProvider.future),
      ).equals(false);
      check(await store.isLoginPending()).equals(true);
      verify(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace?>(),
          'Failed to clear unconfirmed login tokens on startup',
        ),
      ).called(1);

      // ストレージが回復した次回起動では残留トークンと未確定フラグが両方消去されること
      fakeStorage.shouldThrowOnClear = false;
      final recoveredContainer = createContainer(fakeStorage: fakeStorage);
      check(
        await recoveredContainer.read(authStateProvider.future),
      ).equals(false);
      check(fakeStorage.mockAccessToken).isNull();
      check(await store.isLoginPending()).equals(false);
    });

    test('login: 保存後の未確定フラグ解除に失敗した場合はトークンをロールバック消去し '
        '再起動時もログイン状態にしないこと', () async {
      final clearPendingError = Exception('clear pending failed');
      final mockStore = MockCustomAuthInvalidationStore();
      var isPending = false;
      when(
        () => mockStore.clearIfAllowedForLogin(
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          isDeletionInProgress: any(named: 'isDeletionInProgress'),
        ),
      ).thenAnswer((_) async => true);
      when(mockStore.markLoginPending).thenAnswer((_) async {
        isPending = true;
      });
      var clearPendingCalls = 0;
      when(mockStore.clearLoginPending).thenAnswer((_) async {
        clearPendingCalls++;
        throw clearPendingError;
      });
      when(mockStore.clearLogoutPending).thenAnswer((_) async {});
      when(mockStore.isLoginPending).thenAnswer((_) async => isPending);
      when(mockStore.isLogoutPending).thenAnswer((_) async => false);
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);

      final fakeStorage = FakeTokenStorage();
      final container = createContainer(
        fakeStorage: fakeStorage,
        mockInvalidationStore: mockStore,
      );
      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      await check(
        notifier.login('saved-access', 'saved-refresh'),
      ).throws<Exception>((it) => it.equals(clearPendingError));

      check(fakeStorage.isClearCalled).equals(true);
      check(fakeStorage.mockAccessToken).isNull();
      check(clearPendingCalls).equals(2);
      verify(
        () => mockTalker.handle(
          clearPendingError,
          any<StackTrace?>(),
          'Failed to clear pending login flag after token rollback',
        ),
      ).called(1);

      final restartedContainer = createContainer(
        fakeStorage: fakeStorage,
        mockInvalidationStore: mockStore,
      );
      check(
        await restartedContainer.read(authStateProvider.future),
      ).equals(false);
    });

    test('login: 無効化状態の確認・解除に失敗した場合は saveTokens を呼ばず資格情報を保存しないこと', () async {
      final fakeStorage = FakeTokenStorage();
      final mockStore = MockCustomAuthInvalidationStore();
      final clearAllowedError = Exception('clearIfAllowedForLogin failed');
      when(mockStore.isLoginPending).thenAnswer((_) async => false);
      when(mockStore.isLogoutPending).thenAnswer((_) async => false);
      when(mockStore.markLogoutPending).thenAnswer((_) async {});
      when(mockStore.clearLogoutPending).thenAnswer((_) async {});
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);
      when(mockStore.markLoginPending).thenAnswer((_) async {});
      when(
        () => mockStore.clearIfAllowedForLogin(
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          isDeletionInProgress: any(named: 'isDeletionInProgress'),
        ),
      ).thenAnswer((_) async => throw clearAllowedError);

      final container = createContainer(
        fakeStorage: fakeStorage,
        mockInvalidationStore: mockStore,
      );
      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      await check(
        notifier.login('new-access', 'new-refresh'),
      ).throws<Exception>((it) => it.equals(clearAllowedError));

      verify(mockStore.markLoginPending).called(1);
      verify(
        () => mockStore.clearIfAllowedForLogin(
          userId: null,
          email: null,
          isDeletionInProgress: false,
        ),
      ).called(1);
      verifyNever(mockStore.clearLoginPending);
      check(fakeStorage.isSaveTokensCalled).equals(false);
      check(fakeStorage.mockAccessToken).isNull();
      check(container.read(authStateProvider).hasError).equals(true);
    });

    test('login: markLoginPending 後に clearIfAllowedForLogin が失敗した場合も '
        '未確定マーカーが残り、次回起動時に残留トークンを復元せず消去すること', () async {
      final callOrder = <String>[];
      final clearAllowedError = Exception('clearIfAllowedForLogin failed');
      final mockStore = MockCustomAuthInvalidationStore();
      var isPending = false;
      when(mockStore.markLoginPending).thenAnswer((_) async {
        callOrder.add('markLoginPending');
        isPending = true;
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
      when(mockStore.clearLoginPending).thenAnswer((_) async {
        isPending = false;
      });
      when(mockStore.isLoginPending).thenAnswer((_) async => isPending);
      when(mockStore.isLogoutPending).thenAnswer((_) async => false);
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);

      final fakeStorage = FakeTokenStorage(mockAccessToken: 'residual-token');
      final container = createContainer(
        fakeStorage: fakeStorage,
        mockInvalidationStore: mockStore,
      );
      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      await check(
        notifier.login('new-access', 'new-refresh'),
      ).throws<Exception>((it) => it.equals(clearAllowedError));

      check(
        callOrder,
      ).deepEquals(['markLoginPending', 'clearIfAllowedForLogin']);
      check(fakeStorage.isSaveTokensCalled).equals(false);
      check(isPending).equals(true);

      final restartedContainer = createContainer(
        fakeStorage: fakeStorage,
        mockInvalidationStore: mockStore,
      );
      check(
        await restartedContainer.read(authStateProvider.future),
      ).equals(false);
      check(fakeStorage.mockAccessToken).isNull();
      check(isPending).equals(false);
    });

    test(
      'loginWithCredentials: 認証に成功した場合、リポジトリのloginを呼び出し、state を true に更新すること',
      () async {
        // Arrange
        final fakeStorage = FakeTokenStorage();
        final mockAuthRepository = MockAuthRepository();
        when(
          () => mockAuthRepository.login(
            any(),
            any(),
            startSessionEpoch: any(named: 'startSessionEpoch'),
            startDeletionEpoch: any(named: 'startDeletionEpoch'),
          ),
        ).thenAnswer((_) async => true);
        final container = createContainer(
          fakeStorage: fakeStorage,
          mockAuthRepository: mockAuthRepository,
        );

        // buildの完了を待つ
        await container.read(authStateProvider.future);
        final notifier = container.read(authStateProvider.notifier);

        // Act
        final loggedIn = await notifier.loginWithCredentials(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        verify(
          () => mockAuthRepository.login(
            'test@example.com',
            'password123',
            startSessionEpoch: 0,
            startDeletionEpoch: 0,
          ),
        ).called(1);
        check(loggedIn).equals(true);
        check(container.read(authStateProvider).value).equals(true);
      },
    );

    test(
      'loginWithCredentials: 古い応答が破棄(false)された場合は state を変更せず false を返すこと',
      () async {
        final fakeStorage = FakeTokenStorage();
        final mockAuthRepository = MockAuthRepository();
        when(
          () => mockAuthRepository.login(
            any(),
            any(),
            startSessionEpoch: any(named: 'startSessionEpoch'),
            startDeletionEpoch: any(named: 'startDeletionEpoch'),
          ),
        ).thenAnswer((_) async => false);
        final container = createContainer(
          fakeStorage: fakeStorage,
          mockAuthRepository: mockAuthRepository,
        );

        await container.read(authStateProvider.future);
        final notifier = container.read(authStateProvider.notifier);
        check(container.read(authStateProvider).value).equals(false);

        final loggedIn = await notifier.loginWithCredentials(
          email: 'stale@example.com',
          password: 'password123',
        );

        check(loggedIn).equals(false);
        check(container.read(authStateProvider).value).equals(false);
        check(container.read(authStateProvider).hasError).equals(false);
      },
    );

    test(
      'loginWithCredentials: 認証に失敗した場合、例外がスローされ state が AsyncError になること',
      () async {
        // Arrange
        final fakeStorage = FakeTokenStorage();
        final mockAuthRepository = MockAuthRepository();
        when(
          () => mockAuthRepository.login(
            any(),
            any(),
            startSessionEpoch: any(named: 'startSessionEpoch'),
            startDeletionEpoch: any(named: 'startDeletionEpoch'),
          ),
        ).thenThrow(Exception('Login failed'));
        final container = createContainer(
          fakeStorage: fakeStorage,
          mockAuthRepository: mockAuthRepository,
        );

        // buildの完了を待つ
        await container.read(authStateProvider.future);
        final notifier = container.read(authStateProvider.notifier);

        // Act & Assert
        await check(
          notifier.loginWithCredentials(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).throws<Exception>();

        // Assert
        verify(
          () => mockAuthRepository.login(
            'test@example.com',
            'password123',
            startSessionEpoch: 0,
            startDeletionEpoch: 0,
          ),
        ).called(1);
        check(container.read(authStateProvider).hasError).equals(true);
      },
    );

    test('loginWithCredentials: 失敗時に別セッションへ遷移済み(sessionEpoch不一致)の場合は '
        'state を AsyncError にせず例外のみ再スローすること', () async {
      final fakeStorage = FakeTokenStorage();
      final mockAuthRepository = MockAuthRepository();
      final loginStarted = Completer<void>();
      final loginCompleter = Completer<bool>();
      when(
        () => mockAuthRepository.login(
          any(),
          any(),
          startSessionEpoch: any(named: 'startSessionEpoch'),
          startDeletionEpoch: any(named: 'startDeletionEpoch'),
        ),
      ).thenAnswer((_) {
        loginStarted.complete();
        return loginCompleter.future;
      });

      final container = createContainer(
        fakeStorage: fakeStorage,
        mockAuthRepository: mockAuthRepository,
      );
      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      final staleFuture = check(
        notifier.loginWithCredentials(
          email: 'stale@example.com',
          password: 'password123',
        ),
      ).throws<Exception>();
      await loginStarted.future;

      // 別のログインが完了し sessionEpoch と state=true が確定した後に古い要求が失敗する
      check(await notifier.login('new-access', 'new-refresh')).equals(true);
      check(container.read(authStateProvider).value).equals(true);

      loginCompleter.completeError(Exception('Stale login timeout'));
      await staleFuture;

      check(container.read(authStateProvider).hasError).equals(false);
      check(container.read(authStateProvider).value).equals(true);
    });

    test('loginWithCredentials: 失敗時に削除完了済み(deletionEpoch不一致)の場合は '
        'state を AsyncError にせず例外のみ再スローすること', () async {
      final fakeStorage = FakeTokenStorage();
      final mockAuthRepository = MockAuthRepository();
      final loginStarted = Completer<void>();
      final loginCompleter = Completer<bool>();
      when(
        () => mockAuthRepository.login(
          any(),
          any(),
          startSessionEpoch: any(named: 'startSessionEpoch'),
          startDeletionEpoch: any(named: 'startDeletionEpoch'),
        ),
      ).thenAnswer((_) {
        loginStarted.complete();
        return loginCompleter.future;
      });

      final container = createContainer(
        fakeStorage: fakeStorage,
        mockAuthRepository: mockAuthRepository,
      );
      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      final staleFuture = check(
        notifier.loginWithCredentials(
          email: 'stale@example.com',
          password: 'password123',
        ),
      ).throws<Exception>();
      await loginStarted.future;

      // 待機中に削除完了が記録されて deletionEpoch が進む
      container.read(authSessionLockProvider).markDeletionCompleted();

      loginCompleter.completeError(Exception('Stale login failed'));
      await staleFuture;

      check(container.read(authStateProvider).hasError).equals(false);
      check(container.read(authStateProvider).value).equals(false);
    });

    test(
      'loginWithCredentials: build 完了を待機してからログインし state を true にすること',
      () async {
        // Arrange
        final tokenCompleter = Completer<String?>();
        final fakeStorage = FakeTokenStorage(
          mockAccessTokenFuture: tokenCompleter.future,
        );
        final mockAuthRepository = MockAuthRepository();
        when(
          () => mockAuthRepository.login(
            any(),
            any(),
            startSessionEpoch: any(named: 'startSessionEpoch'),
            startDeletionEpoch: any(named: 'startDeletionEpoch'),
          ),
        ).thenAnswer((_) async => true);

        final container = createContainer(
          fakeStorage: fakeStorage,
          mockAuthRepository: mockAuthRepository,
        );
        final notifier = container.read(authStateProvider.notifier);

        // Act: build() がまだ完了していないタイミングでログインを実行
        final loginFuture = notifier.loginWithCredentials(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert: build() の完了待ちのため、この時点ではまだ login は呼ばれていないこと
        verifyNever(
          () => mockAuthRepository.login(
            any(),
            any(),
            startSessionEpoch: any(named: 'startSessionEpoch'),
            startDeletionEpoch: any(named: 'startDeletionEpoch'),
          ),
        );

        // 遅延していた初期化を完了させる（保存されたトークンはなし = false）
        tokenCompleter.complete(null);

        // ログイン処理の完了を待機
        await loginFuture;

        // Assert: ログインAPIが呼ばれ、初期化結果で上書きされずに true になっていること
        verify(
          () => mockAuthRepository.login(
            'test@example.com',
            'password123',
            startSessionEpoch: 0,
            startDeletionEpoch: 0,
          ),
        ).called(1);
        check(container.read(authStateProvider).value).equals(true);
      },
    );

    test('loginWithCredentials: build 待機中に logout で sessionEpoch が進んだ場合は '
        '資格情報を保存せず false を返し、ログアウト後の世代で確定しないこと', () async {
      final tokenCompleter = Completer<String?>();
      final fakeStorage = FakeTokenStorage(
        mockAccessTokenFuture: tokenCompleter.future,
        mockAccessToken: 'old-access',
      )..mockRefreshToken = 'old-refresh';
      final mockApi = MockApiClient();
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 200,
          data: {
            'access_token': _buildJwt(
              sub: 'user-stale',
              email: 's@example.com',
            ),
            'refresh_token': 'refresh-stale',
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      final staleLoginFuture = notifier.loginWithCredentials(
        email: 's@example.com',
        password: 'password123',
      );
      final logoutFuture = notifier.logout();

      tokenCompleter.complete('old-access');
      await logoutFuture;

      check(await staleLoginFuture).equals(false);
      check(fakeStorage.mockAccessToken).isNull();
      check(fakeStorage.mockRefreshToken).isNull();
      check(container.read(authStateProvider).value).equals(false);
      check(container.read(authSessionLockProvider).sessionEpoch).equals(1);
    });

    test('loginWithCredentials: build 待機中に deleteAccount 完了で '
        'deletionEpoch が進んだ場合は資格情報を保存せず false を返すこと', () async {
      final tokenCompleter = Completer<String?>();
      final fakeStorage = FakeTokenStorage(
        mockAccessTokenFuture: tokenCompleter.future,
        mockAccessToken: 'old-access',
      )..mockRefreshToken = 'old-refresh';
      final mockApi = MockApiClient();
      final loginGate = Completer<Response<Map<String, dynamic>>>();
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
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) => loginGate.future);

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      final staleLoginFuture = notifier.loginWithCredentials(
        email: 's@example.com',
        password: 'password123',
      );
      final deleteFuture = notifier.deleteAccount();

      tokenCompleter.complete('old-access');
      check(await deleteFuture).equals(true);
      loginGate.complete(
        Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 200,
          data: {
            'access_token': _buildJwt(
              sub: 'user-stale',
              email: 's@example.com',
            ),
            'refresh_token': 'refresh-stale',
          },
        ),
      );

      check(await staleLoginFuture).equals(false);
      check(fakeStorage.mockAccessToken).isNull();
      check(fakeStorage.mockRefreshToken).isNull();
      check(container.read(authStateProvider).value).equals(false);
      check(container.read(authSessionLockProvider).deletionEpoch).equals(1);
    });

    test('logout: トークンを削除し、state を false に更新すること', () async {
      // Arrange
      // ログアウト前はログイン状態 (true) だったと仮定する
      final fakeStorage = FakeTokenStorage(mockAccessToken: 'old_token');
      final container = createContainer(fakeStorage: fakeStorage);
      final notifier = container.read(authStateProvider.notifier);

      // buildの完了を待つ
      await container.read(authStateProvider.future);

      // Act
      await notifier.logout();

      // Assert
      check(fakeStorage.isClearCalled).equals(true); // clear が呼ばれたか
      check(
        container.read(authStateProvider).value,
      ).equals(false); // state が false か
    });

    test('logout: トークンの削除に失敗した場合、例外がスローされ state が AsyncError になること', () async {
      // Arrange
      final fakeStorage = FakeTokenStorage(
        mockAccessToken: 'old_token',
        shouldThrowOnClear: true,
      );
      final container = createContainer(fakeStorage: fakeStorage);
      final notifier = container.read(authStateProvider.notifier);

      // buildの完了を待つ
      await container.read(authStateProvider.future);

      // Act & Assert
      await check(notifier.logout()).throws<Exception>();

      // Assert
      check(fakeStorage.isClearCalled).equals(true); // clear が呼ばれたか
      check(
        container.read(authStateProvider).hasError,
      ).equals(true); // state が AsyncError か
    });

    test('logout: clearInvalidated だけ失敗してもトークン削除済みなら Talker に記録して '
        'state を false で完了すること', () async {
      final fakeStorage = FakeTokenStorage(mockAccessToken: 'old_token');
      final mockStore = MockCustomAuthInvalidationStore();
      final clearError = Exception('Failed to clear invalidation record');
      when(mockStore.isLoginPending).thenAnswer((_) async => false);
      when(mockStore.isLogoutPending).thenAnswer((_) async => false);
      when(mockStore.markLogoutPending).thenAnswer((_) async {});
      when(mockStore.clearLogoutPending).thenAnswer((_) async {});
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);
      when(
        mockStore.clearInvalidated,
      ).thenAnswer((_) async => throw clearError);

      final container = createContainer(
        fakeStorage: fakeStorage,
        mockInvalidationStore: mockStore,
      );
      final notifier = container.read(authStateProvider.notifier);
      await container.read(authStateProvider.future);

      await check(notifier.logout()).completes();

      check(fakeStorage.isClearCalled).equals(true);
      check(container.read(authStateProvider).hasError).equals(false);
      check(container.read(authStateProvider).value).equals(false);
      verify(mockStore.clearInvalidated).called(1);
      verify(
        () => mockTalker.handle(
          clearError,
          any<StackTrace?>(),
          'Failed to clear custom auth invalidation flag on logout',
        ),
      ).called(1);
    });

    test(
      'login と logout は authSessionLockProvider の完了を待ってからストレージ操作を行うこと',
      () async {
        final fakeStorage = FakeTokenStorage();
        final container = createContainer(fakeStorage: fakeStorage);
        await container.read(authStateProvider.future);
        final notifier = container.read(authStateProvider.notifier);
        final lock = container.read(authSessionLockProvider);

        // login が既存ロックを待つことを検証
        final loginLockGate = Completer<void>();
        final loginLockHolder = lock.synchronized(() => loginLockGate.future);

        final loginFuture = notifier.login('access', 'refresh');
        await Future<void>.delayed(Duration.zero);
        check(fakeStorage.isSaveTokensCalled).equals(false);

        loginLockGate.complete();
        await Future.wait<void>([loginLockHolder, loginFuture]);
        check(fakeStorage.isSaveTokensCalled).equals(true);
        check(lock.sessionEpoch).equals(1);

        // logout も既存ロックを待ち、セッション世代を更新することを検証
        final logoutLockGate = Completer<void>();
        final logoutLockHolder = lock.synchronized(() => logoutLockGate.future);

        final logoutFuture = notifier.logout();
        await Future<void>.delayed(Duration.zero);
        check(fakeStorage.isClearCalled).equals(false);
        check(lock.sessionEpoch).equals(1);

        logoutLockGate.complete();
        await Future.wait<void>([logoutLockHolder, logoutFuture]);
        check(fakeStorage.isClearCalled).equals(true);
        check(lock.sessionEpoch).equals(2);
      },
    );

    test('logout: clear() が一部失敗し customUserEmail のみ残留した場合も '
        '消去未完了と signedOut を記録し、次回起動時に全4キー消去成功後のみ記録解除すること', () async {
      final storedValues = <String, String>{};
      final mockSecureStorage = MockFlutterSecureStorage();
      when(
        () => mockSecureStorage.read(key: any(named: 'key')),
      ).thenAnswer((inv) async => storedValues[extractStorageKey('read', inv)]);
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
          storedValues.remove(key);
        } else {
          storedValues[key] = value;
        }
      });
      var failEmailDelete = true;
      when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((
        inv,
      ) async {
        final key = extractStorageKey('delete', inv);
        if (key == SecureStorageKeys.customUserEmail && failEmailDelete) {
          throw Exception('customUserEmail delete failed');
        }
        storedValues.remove(key);
      });

      final realStorage = TokenStorage(secureStorage: mockSecureStorage);
      await realStorage.saveTokens(
        accessToken: 'opaque-access',
        refreshToken: 'opaque-refresh',
        userId: 'user-a',
        email: 'a@example.com',
      );

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      check(await container.read(authStateProvider.future)).equals(true);
      final notifier = container.read(authStateProvider.notifier);
      final store = container.read(customAuthInvalidationStoreProvider);
      final lock = container.read(authSessionLockProvider);

      await check(notifier.logout()).throws<Exception>();
      check(container.read(authStateProvider).hasError).equals(true);
      check(lock.currentSession).isA<SignedOutTrackedAuthSession>();
      check(await store.isLogoutPending()).equals(true);
      // accessToken 等が消えて customUserEmail のみ残留した状態になっていること
      check(
        storedValues,
      ).deepEquals({SecureStorageKeys.customUserEmail: 'a@example.com'});

      // 起動時の再消去でも email 削除が失敗する場合は未完了記録を保持し未ログインにすること
      final failedRestart = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(failedRestart.dispose);
      check(await failedRestart.read(authStateProvider.future)).equals(false);
      check(await store.isLogoutPending()).equals(true);
      check(
        storedValues,
      ).deepEquals({SecureStorageKeys.customUserEmail: 'a@example.com'});
      verify(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace?>(),
          'Failed to clear pending logout tokens on startup',
        ),
      ).called(1);

      // ストレージ回復後の起動で全4キーの消去が成功した場合のみ未完了記録を解除すること
      failEmailDelete = false;
      final recoveredRestart = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(recoveredRestart.dispose);
      check(
        await recoveredRestart.read(authStateProvider.future),
      ).equals(false);
      check(storedValues).isEmpty();
      check(await store.isLogoutPending()).equals(false);
    });

    test('logout: clear() 成功後に clearLogoutPending() だけ失敗しても '
        'Talker に記録して state=false で完了し、次回起動で記録を解消すること', () async {
      final fakeStorage = FakeTokenStorage(mockAccessToken: 'old_token');
      final mockStore = MockCustomAuthInvalidationStore();
      var isLogoutPending = false;
      final pendingError = Exception('clearLogoutPending failed');
      when(mockStore.isLoginPending).thenAnswer((_) async => false);
      when(mockStore.isLogoutPending).thenAnswer((_) async => isLogoutPending);
      when(mockStore.markLogoutPending).thenAnswer((_) async {
        isLogoutPending = true;
      });
      var clearPendingCalls = 0;
      when(mockStore.clearLogoutPending).thenAnswer((_) async {
        clearPendingCalls++;
        if (clearPendingCalls == 1) {
          throw pendingError;
        }
        isLogoutPending = false;
      });
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);
      when(mockStore.clearInvalidated).thenAnswer((_) async {});

      final container = createContainer(
        fakeStorage: fakeStorage,
        mockInvalidationStore: mockStore,
      );
      final notifier = container.read(authStateProvider.notifier);
      await container.read(authStateProvider.future);

      await check(notifier.logout()).completes();
      check(container.read(authStateProvider).hasError).equals(false);
      check(container.read(authStateProvider).value).equals(false);
      check(isLogoutPending).equals(true);
      verify(
        () => mockTalker.handle(
          pendingError,
          any<StackTrace?>(),
          'Failed to clear pending logout flag on logout',
        ),
      ).called(1);

      final restarted = createContainer(
        fakeStorage: fakeStorage,
        mockInvalidationStore: mockStore,
      );
      check(await restarted.read(authStateProvider.future)).equals(false);
      check(isLogoutPending).equals(false);
    });

    test('logout: 消去一部失敗の直後に別アカウントのログインが成功した場合は '
        '消去未完了記録を解除し、再起動時に新セッションを維持すること', () async {
      final storedValues = <String, String>{};
      final mockSecureStorage = MockFlutterSecureStorage();
      when(
        () => mockSecureStorage.read(key: any(named: 'key')),
      ).thenAnswer((inv) async => storedValues[extractStorageKey('read', inv)]);
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
          storedValues.remove(key);
        } else {
          storedValues[key] = value;
        }
      });
      var failEmailDelete = true;
      when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((
        inv,
      ) async {
        final key = extractStorageKey('delete', inv);
        if (key == SecureStorageKeys.customUserEmail && failEmailDelete) {
          throw Exception('customUserEmail delete failed');
        }
        storedValues.remove(key);
      });

      final realStorage = TokenStorage(secureStorage: mockSecureStorage);
      await realStorage.saveTokens(
        accessToken: 'opaque-a',
        refreshToken: 'refresh-a',
        email: 'a@example.com',
      );
      final mockApi = MockApiClient();
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 200,
          data: {'access_token': 'opaque-b', 'refresh_token': 'refresh-b'},
        ),
      );

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

      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);
      final store = container.read(customAuthInvalidationStoreProvider);

      await check(notifier.logout()).throws<Exception>();
      check(await store.isLogoutPending()).equals(true);

      failEmailDelete = false;
      check(
        await notifier.loginWithCredentials(
          email: 'b@example.com',
          password: 'password123',
        ),
      ).equals(true);
      check(await store.isLogoutPending()).equals(false);

      final restarted = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(restarted.dispose);
      check(await restarted.read(authStateProvider.future)).equals(true);
      check(storedValues[SecureStorageKeys.accessToken]).equals('opaque-b');
      check(
        storedValues[SecureStorageKeys.customUserEmail],
      ).equals('b@example.com');
    });

    test('logout: 通常経路では markLogoutPending を tokenStorage.clear() より先に実行し '
        '完了後に clearLogoutPending を実行すること', () async {
      final fakeStorage = FakeTokenStorage(mockAccessToken: 'old_token');
      final mockStore = MockCustomAuthInvalidationStore();
      final callOrder = <String>[];
      when(mockStore.isLoginPending).thenAnswer((_) async => false);
      when(mockStore.isLogoutPending).thenAnswer((_) async => false);
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);
      when(mockStore.markLogoutPending).thenAnswer((_) async {
        check(fakeStorage.isClearCalled).equals(false);
        callOrder.add('markLogoutPending');
      });
      when(mockStore.clearLogoutPending).thenAnswer((_) async {
        check(fakeStorage.isClearCalled).equals(true);
        callOrder.add('clearLogoutPending');
      });
      when(mockStore.clearInvalidated).thenAnswer((_) async {
        callOrder.add('clearInvalidated');
      });

      final container = createContainer(
        fakeStorage: fakeStorage,
        mockInvalidationStore: mockStore,
      );
      final notifier = container.read(authStateProvider.notifier);
      await container.read(authStateProvider.future);

      await check(notifier.logout()).completes();
      check(callOrder).deepEquals([
        'markLogoutPending',
        'clearLogoutPending',
        'clearInvalidated',
      ]);
      check(container.read(authStateProvider).value).equals(false);
    });

    test('logout: markLogoutPending が失敗しても tokenStorage.clear() を試行し、 '
        '全キー消去に成功した場合は未ログイン(false)へ遷移すること', () async {
      final fakeStorage = FakeTokenStorage(mockAccessToken: 'old_token');
      final mockStore = MockCustomAuthInvalidationStore();
      final markError = Exception('markLogoutPending failed');
      when(mockStore.isLoginPending).thenAnswer((_) async => false);
      when(mockStore.isLogoutPending).thenAnswer((_) async => false);
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);
      when(mockStore.markLogoutPending).thenThrow(markError);
      when(mockStore.clearInvalidated).thenAnswer((_) async {});

      final container = createContainer(
        fakeStorage: fakeStorage,
        mockInvalidationStore: mockStore,
      );
      final notifier = container.read(authStateProvider.notifier);
      await container.read(authStateProvider.future);

      await check(notifier.logout()).completes();
      check(fakeStorage.isClearCalled).equals(true);
      check(fakeStorage.mockAccessToken).isNull();
      check(container.read(authStateProvider).hasError).equals(false);
      check(container.read(authStateProvider).value).equals(false);
      verifyNever(mockStore.clearLogoutPending);
      verify(
        () => mockTalker.handle(
          markError,
          any<StackTrace?>(),
          'Failed to record pending logout flag on logout',
        ),
      ).called(1);
    });

    test('logout: markLogoutPending と tokenStorage.clear() が両方失敗した場合は '
        'ログアウトを成功扱いにせず例外送出と AsyncError にすること', () async {
      final fakeStorage = FakeTokenStorage(
        mockAccessToken: 'old_token',
        shouldThrowOnClear: true,
      );
      final mockStore = MockCustomAuthInvalidationStore();
      final markError = Exception('markLogoutPending failed');
      when(mockStore.isLoginPending).thenAnswer((_) async => false);
      when(mockStore.isLogoutPending).thenAnswer((_) async => false);
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);
      when(mockStore.markLogoutPending).thenThrow(markError);

      final container = createContainer(
        fakeStorage: fakeStorage,
        mockInvalidationStore: mockStore,
      );
      final notifier = container.read(authStateProvider.notifier);
      await container.read(authStateProvider.future);

      await check(notifier.logout()).throws<Exception>();
      check(fakeStorage.isClearCalled).equals(true);
      check(container.read(authStateProvider).hasError).equals(true);
      verifyNever(mockStore.clearLogoutPending);
      verify(
        () => mockTalker.handle(
          markError,
          any<StackTrace?>(),
          'Failed to record pending logout flag on logout',
        ),
      ).called(1);
    });
  });

  group('AuthStateNotifier (deleteAccount)', () {
    test('deleteAccount: 対象セッション終了(true)時は state が AsyncData(false) になり '
        'true を返すこと', () async {
      final fakeStorage = FakeTokenStorage(mockAccessToken: 'valid_token');
      final mockRepo = MockAuthRepository();
      when(mockRepo.deleteAccount).thenAnswer((_) async => true);

      final container = createContainer(
        fakeStorage: fakeStorage,
        mockAuthRepository: mockRepo,
      );
      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      final result = await notifier.deleteAccount();

      verify(mockRepo.deleteAccount).called(1);
      check(result).equals(true);
      check(container.read(authStateProvider).value).equals(false);
      check(container.read(authStateProvider).hasError).equals(false);
    });

    test('deleteAccount: 別セッション保護(false)時はログイン状態(true)を維持し '
        'false を返すこと', () async {
      final fakeStorage = FakeTokenStorage(mockAccessToken: 'valid_token');
      final mockRepo = MockAuthRepository();
      when(mockRepo.deleteAccount).thenAnswer((_) async => false);

      final container = createContainer(
        fakeStorage: fakeStorage,
        mockAuthRepository: mockRepo,
      );
      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      final result = await notifier.deleteAccount();

      verify(mockRepo.deleteAccount).called(1);
      check(result).equals(false);
      check(container.read(authStateProvider).value).equals(true);
      check(container.read(authStateProvider).hasError).equals(false);
    });

    test('deleteAccount: API失敗時は例外が再スローされ、ログイン状態(true)を維持すること', () async {
      final fakeStorage = FakeTokenStorage(mockAccessToken: 'valid_token');
      final mockRepo = MockAuthRepository();
      when(mockRepo.deleteAccount).thenThrow(Exception('Delete API failed'));

      final container = createContainer(
        fakeStorage: fakeStorage,
        mockAuthRepository: mockRepo,
      );
      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      await check(notifier.deleteAccount()).throws<Exception>();

      verify(mockRepo.deleteAccount).called(1);
      check(container.read(authStateProvider).value).equals(true);
      check(container.read(authStateProvider).hasError).equals(false);
    });

    test('login / logout 実行時はセッション無効化フラグを解除すること', () async {
      final fakeStorage = FakeTokenStorage(mockAccessToken: 'stale_token');
      final store = CustomAuthInvalidationStore(
        getDirectory: () async => tempDir,
      );
      await store.markInvalidated();
      final container = createContainer(fakeStorage: fakeStorage);
      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      await store.markInvalidated();
      check(invalidationDbFile().existsSync()).equals(true);
      await notifier.login('new_access', 'new_refresh');
      check(await store.isInvalidated()).equals(false);
      check(container.read(authStateProvider).value).equals(true);

      await store.markInvalidated();
      check(invalidationDbFile().existsSync()).equals(true);
      await notifier.logout();
      check(await store.isInvalidated()).equals(false);
      check(container.read(authStateProvider).value).equals(false);
    });

    test('実AuthRepository連携: 削除待機中に同一アカウントで notifier.login が完了しても、 '
        '完了時にトークン消去と state=false が確定し再起動後も復元されないこと', () async {
      final tokenA1 = _buildJwt(sub: 'user-a', email: 'a@example.com');
      final tokenA2 = _buildJwt(sub: 'user-a', email: 'a@example.com');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenA1);
      final mockApi = MockApiClient();
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

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      final deleteFuture = notifier.deleteAccount();
      await deleteStarted.future;

      await notifier.login(tokenA2, 'refresh-a2');
      check(container.read(authStateProvider).value).equals(true);

      final store = container.read(customAuthInvalidationStoreProvider);
      check(await store.isInvalidated()).equals(true);

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture).equals(true);

      check(fakeStorage.mockAccessToken).isNull();
      check(await store.isInvalidated()).equals(false);
      check(container.read(authStateProvider).value).equals(false);

      final restarted = createContainer(fakeStorage: fakeStorage);
      check(await restarted.read(authStateProvider.future)).equals(false);
    });

    test('実AuthRepository連携: 削除待機中に別アカウントで notifier.login が完了した場合は、 '
        '削除完了後も別アカウントのトークンと state=true を維持すること', () async {
      final tokenA = _buildJwt(sub: 'user-a', email: 'a@example.com');
      final tokenB = _buildJwt(sub: 'user-b', email: 'b@example.com');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenA);
      final mockApi = MockApiClient();
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

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      final deleteFuture = notifier.deleteAccount();
      await deleteStarted.future;

      await notifier.login(tokenB, 'refresh-b');
      final store = container.read(customAuthInvalidationStoreProvider);
      // A の退会進行中は別アカウントログインでも A 所有の無効化レコードを消さないこと
      check(await store.isInvalidated()).equals(true);
      check((await store.getInvalidationState()).targetUserId).equals('user-a');

      // そのまま完了前に再起動相当で build() しても B のトークンを維持し、古い A レコードを片付けること
      final midRestartContainer = createContainer(fakeStorage: fakeStorage);
      check(
        await midRestartContainer.read(authStateProvider.future),
      ).equals(true);
      check(fakeStorage.mockAccessToken).equals(tokenB);
      check(await store.isInvalidated()).equals(false);

      // 後続テスト用に A の退会中レコードを残した状態で完了させた場合も A 完了で解除されること
      await store.markInvalidated(
        targetUserId: 'user-a',
        targetEmail: 'a@example.com',
      );
      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture).equals(false);

      check(await store.isInvalidated()).equals(false);
      check(fakeStorage.mockAccessToken).equals(tokenB);
      check(container.read(authStateProvider).value).equals(true);
    });

    test('実AuthRepository連携: A の退会中に B がログインしてさらに B も退会開始した場合、 '
        'A 完了時は B の無効化レコードとログイン状態を残し B 完了時にのみ B を未ログインにすること', () async {
      final tokenA = _buildJwt(sub: 'user-a', email: 'a@example.com');
      final tokenB = _buildJwt(sub: 'user-b', email: 'b@example.com');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenA);
      final mockApi = MockApiClient();

      final deleteStartedA = Completer<void>();
      final deleteCompleterA = Completer<Response<void>>();
      final deleteStartedB = Completer<void>();
      final deleteCompleterB = Completer<Response<void>>();
      var deleteCalls = 0;
      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) {
        deleteCalls++;
        if (deleteCalls == 1) {
          deleteStartedA.complete();
          return deleteCompleterA.future;
        }
        deleteStartedB.complete();
        return deleteCompleterB.future;
      });

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);
      final store = container.read(customAuthInvalidationStoreProvider);

      final deleteFutureA = notifier.deleteAccount();
      await deleteStartedA.future;

      await notifier.login(tokenB, 'refresh-b');
      check(container.read(authStateProvider).value).equals(true);
      check((await store.getInvalidationState()).targetUserId).equals('user-a');

      final deleteFutureB = notifier.deleteAccount();
      await deleteStartedB.future;
      final entriesWhileBothDeleting = await store.getInvalidationEntries();
      check(entriesWhileBothDeleting).length.equals(2);
      check(entriesWhileBothDeleting[0].targetUserId).equals('user-a');
      check(entriesWhileBothDeleting[1].targetUserId).equals('user-b');
      check((await store.getInvalidationState()).targetUserId).equals('user-b');

      // A の退会後処理が先に完了しても B 所有の無効化レコード・トークン・認証状態は維持されること
      deleteCompleterA.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFutureA).equals(false);
      check(fakeStorage.mockAccessToken).equals(tokenB);
      check(container.read(authStateProvider).value).equals(true);
      final entriesAfterA = await store.getInvalidationEntries();
      check(entriesAfterA).length.equals(1);
      check(entriesAfterA.single.targetUserId).equals('user-b');
      check((await store.getInvalidationState()).targetUserId).equals('user-b');

      // B 自身の退会完了時のみ B のトークンとレコードをクリアし未ログインにすること
      deleteCompleterB.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFutureB).equals(true);
      check(fakeStorage.mockAccessToken).isNull();
      check(await store.isInvalidated()).equals(false);
      check(container.read(authStateProvider).value).equals(false);
    });

    test('実AuthRepository連携: サーバー削除確定後に tokenStorage.clear() が失敗しても '
        '無効化レコード解除は呼ばずに保持し、state=false と true 返却で完了すること', () async {
      final tokenA = _buildJwt(sub: 'user-a', email: 'a@example.com');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenA);
      final mockApi = MockApiClient();
      final mockStore = MockCustomAuthInvalidationStore();
      when(mockStore.isLoginPending).thenAnswer((_) async => false);
      when(mockStore.isLogoutPending).thenAnswer((_) async => false);
      when(mockStore.markLogoutPending).thenAnswer((_) async {});
      when(mockStore.clearLogoutPending).thenAnswer((_) async {});
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);
      when(
        () => mockStore.markInvalidated(
          targetUserId: any(named: 'targetUserId'),
          targetEmail: any(named: 'targetEmail'),
        ),
      ).thenAnswer((_) async => 1);
      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) async {
        // 削除確定直後に端末ストレージのトークン消去が失敗する状態を模擬
        // （無効化レコードはトークン残留保護のため解除しない）
        fakeStorage.shouldThrowOnClear = true;
        return Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        );
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

      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      final result = await notifier.deleteAccount();

      check(result).equals(true);
      check(fakeStorage.isClearCalled).equals(true);
      check(fakeStorage.mockAccessToken).equals(tokenA);
      check(container.read(authStateProvider).value).equals(false);
      check(container.read(authStateProvider).hasError).equals(false);
      verify(
        () => mockStore.markInvalidated(
          targetUserId: 'user-a',
          targetEmail: 'a@example.com',
        ),
      ).called(1);
      verifyNever(
        () => mockStore.clearInvalidatedIfMatches(
          targetUserId: any(named: 'targetUserId'),
          targetEmail: any(named: 'targetEmail'),
          entryId: any(named: 'entryId'),
        ),
      );
      verify(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace?>(),
          'Failed to clear local tokens after account deletion',
        ),
      ).called(1);
    });

    test('実AuthRepository連携: サーバー削除確定後に clearInvalidatedIfMatches が失敗しても '
        'Talker に記録して state=false と true 返却で完了すること', () async {
      final tokenA = _buildJwt(sub: 'user-a', email: 'a@example.com');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenA);
      final mockApi = MockApiClient();
      final mockStore = MockCustomAuthInvalidationStore();
      final dbError = Exception('DB clear failed after deletion');
      when(mockStore.isLoginPending).thenAnswer((_) async => false);
      when(mockStore.isLogoutPending).thenAnswer((_) async => false);
      when(mockStore.getInvalidationEntries).thenAnswer((_) async => const []);
      when(
        () => mockStore.markInvalidated(
          targetUserId: any(named: 'targetUserId'),
          targetEmail: any(named: 'targetEmail'),
        ),
      ).thenAnswer((_) async => 1);
      when(
        () => mockStore.clearInvalidatedIfMatches(
          targetUserId: any(named: 'targetUserId'),
          targetEmail: any(named: 'targetEmail'),
          entryId: any(named: 'entryId'),
        ),
      ).thenAnswer((_) async => throw dbError);
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

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          customAuthInvalidationStoreProvider.overrideWithValue(mockStore),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      final result = await notifier.deleteAccount();

      check(result).equals(true);
      check(fakeStorage.isClearCalled).equals(true);
      check(fakeStorage.mockAccessToken).isNull();
      check(container.read(authStateProvider).value).equals(false);
      check(container.read(authStateProvider).hasError).equals(false);
      verify(
        () => mockStore.markInvalidated(
          targetUserId: 'user-a',
          targetEmail: 'a@example.com',
        ),
      ).called(1);
      verify(
        () => mockStore.clearInvalidatedIfMatches(
          targetUserId: 'user-a',
          targetEmail: 'a@example.com',
        ),
      ).called(1);
      verify(
        () => mockTalker.handle(
          dbError,
          any<StackTrace?>(),
          'Failed to clear invalidated custom auth session flag',
        ),
      ).called(1);
    });

    test('実AuthRepository連携: 削除前に開始した loginWithCredentials の応答が '
        'deleteAccount 完了後に届いても破棄され未ログイン(false)を維持すること', () async {
      final tokenOld = _buildJwt(sub: 'user-a', email: 'a@example.com');
      final tokenStaleLogin = _buildJwt(sub: 'user-b', email: 'b@example.com');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenOld);
      final mockApi = MockApiClient();

      final loginStarted = Completer<void>();
      final loginGate = Completer<Map<String, dynamic>>();
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer((_) async {
        loginStarted.complete();
        final data = await loginGate.future;
        return Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 200,
          data: data,
        );
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

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      final loginFuture = notifier.loginWithCredentials(
        email: 'b@example.com',
        password: 'password123',
      );
      await loginStarted.future;

      check(await notifier.deleteAccount()).equals(true);
      check(container.read(authStateProvider).value).equals(false);
      check(fakeStorage.mockAccessToken).isNull();

      loginGate.complete({
        'access_token': tokenStaleLogin,
        'refresh_token': 'refresh-stale',
      });

      check(await loginFuture).equals(false);
      check(fakeStorage.mockAccessToken).isNull();
      check(container.read(authStateProvider).value).equals(false);
      check(container.read(authStateProvider).hasError).equals(false);
    });

    test('実AuthRepository連携: 削除待機中に同一アカウントで再ログインした後、 '
        '削除成功後のストレージ読み取りが失敗しても state=false と true 返却で完了すること', () async {
      final tokenA1 = _buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'initial',
      );
      final tokenA2 = _buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'relogin',
      );
      check(tokenA2).not((it) => it.equals(tokenA1));

      for (final isUserIdFailure in [false, true]) {
        final fakeStorage = FakeTokenStorage(mockAccessToken: tokenA1);
        final mockApi = MockApiClient();

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

        final container = ProviderContainer(
          overrides: [
            authApiClientProvider.overrideWithValue(mockApi),
            tokenStorageProvider.overrideWith((ref) => fakeStorage),
            appSupportDirectoryReaderProvider.overrideWithValue(
              () async => tempDir,
            ),
            loggerProvider.overrideWithValue(mockTalker),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authStateProvider.future);
        final notifier = container.read(authStateProvider.notifier);

        final deleteFuture = notifier.deleteAccount();
        await deleteStarted.future;

        await notifier.login(tokenA2, 'refresh-a2');
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

        check(await deleteFuture).equals(true);
        check(container.read(authStateProvider).value).equals(false);
        check(fakeStorage.mockAccessToken).isNull();
        check(fakeStorage.isClearCalled).equals(true);
        final store = container.read(customAuthInvalidationStoreProvider);
        check(await store.isInvalidated()).equals(false);
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

    test('実AuthRepository連携: 削除待機中に別アカウントへ切り替わった後、 '
        '削除成功後のストレージ読み取りが失敗しても別アカウントのトークンと state=true を維持すること', () async {
      final tokenA = _buildJwt(sub: 'user-a', email: 'a@example.com');
      final tokenB = _buildJwt(sub: 'user-b', email: 'b@example.com');

      for (final isUserIdFailure in [false, true]) {
        final fakeStorage = FakeTokenStorage(mockAccessToken: tokenA);
        final mockApi = MockApiClient();

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

        final container = ProviderContainer(
          overrides: [
            authApiClientProvider.overrideWithValue(mockApi),
            tokenStorageProvider.overrideWith((ref) => fakeStorage),
            appSupportDirectoryReaderProvider.overrideWithValue(
              () async => tempDir,
            ),
            loggerProvider.overrideWithValue(mockTalker),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authStateProvider.future);
        final notifier = container.read(authStateProvider.notifier);

        final deleteFuture = notifier.deleteAccount();
        await deleteStarted.future;

        await notifier.login(tokenB, 'refresh-b');
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
        check(container.read(authStateProvider).value).equals(true);
        check(fakeStorage.mockAccessToken).equals(tokenB);
        check(fakeStorage.isClearCalled).equals(false);
        final store = container.read(customAuthInvalidationStoreProvider);
        check(await store.isInvalidated()).equals(false);
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

    test('実AuthRepository連携: 削除待機中にサインアウト済みとなった後、 '
        '削除成功後のストレージ読み取りが失敗しても state=false と true 返却で完了すること', () async {
      final tokenA = _buildJwt(sub: 'user-a', email: 'a@example.com');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenA);
      final mockApi = MockApiClient();

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

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      final deleteFuture = notifier.deleteAccount();
      await deleteStarted.future;

      await notifier.logout();
      check(container.read(authStateProvider).value).equals(false);

      final readError = Exception('token read failed');
      fakeStorage.getAccessTokenError = readError;

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );

      check(await deleteFuture).equals(true);
      check(container.read(authStateProvider).value).equals(false);
      verify(
        () => mockTalker.handle(
          readError,
          any<StackTrace?>(),
          'Failed to read current token while resolving account deletion '
          'outcome',
        ),
      ).called(1);
    });

    test('実AuthRepository連携: A と B が並行退会中に再起動した場合、 '
        '先に登録された A のトークンでも復元されず、どちらでもない C のトークンは維持されること', () async {
      final tokenA = _buildJwt(sub: 'user-a', email: 'a@example.com');
      final tokenB = _buildJwt(sub: 'user-b', email: 'b@example.com');
      final tokenC = _buildJwt(sub: 'user-c', email: 'c@example.com');

      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenA);
      final mockApi = MockApiClient();
      final deleteStartedA = Completer<void>();
      final deleteNeverEndsA = Completer<Response<void>>();
      final deleteStartedB = Completer<void>();
      final deleteNeverEndsB = Completer<Response<void>>();
      var calls = 0;
      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) {
        calls++;
        if (calls == 1) {
          deleteStartedA.complete();
          return deleteNeverEndsA.future;
        }
        deleteStartedB.complete();
        return deleteNeverEndsB.future;
      });

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      unawaited(notifier.deleteAccount());
      await deleteStartedA.future;

      await notifier.login(tokenB, 'refresh-b');
      unawaited(notifier.deleteAccount());
      await deleteStartedB.future;

      final store = container.read(customAuthInvalidationStoreProvider);
      check(await store.getInvalidationEntries()).length.equals(2);

      // 強制終了前に何らかの経路で A のトークンが残留して再起動しても A 復元を防ぐこと
      fakeStorage.mockAccessToken = tokenA;
      final restartedWithA = createContainer(fakeStorage: fakeStorage);
      check(await restartedWithA.read(authStateProvider.future)).equals(false);
      check(fakeStorage.mockAccessToken).isNull();
      check(await store.isInvalidated()).equals(false);

      // 一方 A・B 両方の無効化レコードがある状態で無関係な C のトークンなら維持すること
      await store.markInvalidated(
        targetUserId: 'user-a',
        targetEmail: 'a@example.com',
      );
      await store.markInvalidated(
        targetUserId: 'user-b',
        targetEmail: 'b@example.com',
      );
      fakeStorage.mockAccessToken = tokenC;
      final restartedWithC = createContainer(fakeStorage: fakeStorage);
      check(await restartedWithC.read(authStateProvider.future)).equals(true);
      check(fakeStorage.mockAccessToken).equals(tokenC);
      check(await store.isInvalidated()).equals(false);
    });

    test('実AuthRepository連携: 退会進行中の logout() は無効化レコードを保持し、 '
        '再ログイン後に削除完了時のトークン消去へ失敗しても再起動復元されないこと', () async {
      final tokenA1 = _buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'initial',
      );
      final tokenA2 = _buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'relogin',
      );
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenA1);
      final mockApi = MockApiClient();
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

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);
      final store = container.read(customAuthInvalidationStoreProvider);

      final deleteFuture = notifier.deleteAccount();
      await deleteStarted.future;

      await notifier.logout();
      check(container.read(authStateProvider).value).equals(false);
      check(await store.isInvalidated()).equals(true);

      await notifier.login(tokenA2, 'refresh-a2');
      check(await store.isInvalidated()).equals(true);

      fakeStorage.shouldThrowOnClear = true;
      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture).equals(true);
      check(fakeStorage.mockAccessToken).equals(tokenA2);
      check(await store.isInvalidated()).equals(true);

      fakeStorage.shouldThrowOnClear = false;
      final restarted = createContainer(fakeStorage: fakeStorage);
      check(await restarted.read(authStateProvider.future)).equals(false);
      check(fakeStorage.mockAccessToken).isNull();
      check(await store.isInvalidated()).equals(false);
    });

    test('実AuthRepository連携: 削除対象が sub のみ(email なし)のとき、 '
        'notifier.login による識別不能な再ログインを確定させず削除を完了すること', () async {
      final tokenSubOnly = _buildJwt(sub: 'user-a');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenSubOnly);
      final mockApi = MockApiClient();
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

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);
      final store = container.read(customAuthInvalidationStoreProvider);

      final deleteFuture = notifier.deleteAccount();
      await deleteStarted.future;

      check(
        await notifier.login('opaque-without-claims', 'refresh-opaque'),
      ).equals(false);
      check(fakeStorage.mockAccessToken).equals(tokenSubOnly);
      check(await store.isInvalidated()).equals(true);

      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture).equals(true);
      check(container.read(authStateProvider).value).equals(false);
      check(fakeStorage.mockAccessToken).isNull();
      check(await store.isInvalidated()).equals(false);
    });

    test('実AuthRepository連携: 同一アカウントの退会を 2 件並行開始した場合、 '
        '1 件目完了後の再ログインと 2 件目完了時の消去失敗でも再起動復元されないこと', () async {
      final tokenA1 = _buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'del-1',
      );
      final tokenA2 = _buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'del-2',
      );
      final tokenA3 = _buildJwt(
        sub: 'user-a',
        email: 'a@example.com',
        jti: 'relogin',
      );
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenA1);
      final mockApi = MockApiClient();
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

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);
      final store = container.read(customAuthInvalidationStoreProvider);

      final deleteFuture1 = notifier.deleteAccount();
      await deleteStarted1.future;

      await notifier.login(tokenA2, 'refresh-a2');
      final deleteFuture2 = notifier.deleteAccount();
      await deleteStarted2.future;
      check(await store.getInvalidationEntries()).length.equals(2);

      deleteCompleter1.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture1).equals(true);
      check(await store.getInvalidationEntries()).length.equals(1);

      await notifier.login(tokenA3, 'refresh-a3');
      fakeStorage.shouldThrowOnClear = true;
      deleteCompleter2.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture2).equals(true);
      check(fakeStorage.mockAccessToken).equals(tokenA3);
      check(await store.isInvalidated()).equals(true);

      fakeStorage.shouldThrowOnClear = false;
      final restarted = createContainer(fakeStorage: fakeStorage);
      check(await restarted.read(authStateProvider.future)).equals(false);
      check(fakeStorage.mockAccessToken).isNull();
      check(await store.isInvalidated()).equals(false);
    });

    test('実AuthRepository連携: 削除対象に email があり待機中の loginWithCredentials が '
        'sub/email なしトークンを返しても入力メールで同一アカウントと判定し未ログイン化すること', () async {
      final tokenA = _buildJwt(sub: 'user-a', email: 'a@example.com');
      final opaqueRelogin = _buildJwt(jti: 'opaque-relogin-a');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenA);
      final mockApi = MockApiClient();

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
      when(
        () => mockApi.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 200,
          data: {
            'access_token': opaqueRelogin,
            'refresh_token': 'refresh-opaque-a',
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          tokenStorageProvider.overrideWith((ref) => fakeStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);
      final store = container.read(customAuthInvalidationStoreProvider);

      final deleteFuture = notifier.deleteAccount();
      await deleteStarted.future;

      // sub/email クレームの無いトークンが返っても、入力メール a@example.com で照合して再ログインを許可する
      check(
        await notifier.loginWithCredentials(
          email: 'a@example.com',
          password: 'password123',
        ),
      ).equals(true);
      check(fakeStorage.mockAccessToken).equals(opaqueRelogin);
      check(await store.isInvalidated()).equals(true);

      // 削除完了時は保持された入力メールを補完して同一アカウント (true) と判定し消去すること
      deleteCompleter.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture).equals(true);
      check(container.read(authStateProvider).value).equals(false);
      check(fakeStorage.mockAccessToken).isNull();
      check(await store.isInvalidated()).equals(false);
    });

    test('実AuthRepository連携: 実TokenStorageでクレーム無しトークンと入力メールを永続化し、 '
        '再起動後の AuthStateNotifier.build() で同一アカウント消去と別アカウント保護ができること', () async {
      final storedValues = <String, String>{};
      final mockSecureStorage = MockFlutterSecureStorage();
      when(() => mockSecureStorage.read(key: any(named: 'key'))).thenAnswer(
        (inv) async => storedValues[inv.namedArguments[#key] as String],
      );
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
          storedValues.remove(key);
        } else {
          storedValues[key] = value;
        }
      });
      final deleteError = Exception('clear failed on deletion completion');
      var shouldFailDelete = false;
      when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((
        inv,
      ) async {
        if (shouldFailDelete) {
          throw deleteError;
        }
        storedValues.remove(inv.namedArguments[#key] as String);
      });

      final realStorage = TokenStorage(secureStorage: mockSecureStorage);
      final tokenA = _buildJwt(sub: 'user-a', email: 'a@example.com');
      final opaqueReloginA = _buildJwt(jti: 'opaque-relogin-a');
      final opaqueLoginB = _buildJwt(jti: 'opaque-login-b');

      // 1. 同一アカウント A が入力メール + クレーム無しトークンで再ログインし、
      //    消去失敗したまま再起動しても保存済み customUserEmail で同一判定・消去されること
      await realStorage.saveTokens(accessToken: tokenA, refreshToken: 'ref-a');
      final mockApi1 = MockApiClient();
      final deleteStarted1 = Completer<void>();
      final deleteCompleter1 = Completer<Response<void>>();
      when(
        () => mockApi1.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) {
        deleteStarted1.complete();
        return deleteCompleter1.future;
      });
      when(
        () => mockApi1.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 200,
          data: {'access_token': opaqueReloginA, 'refresh_token': 'ref-op-a'},
        ),
      );

      final container1 = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi1),
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container1.dispose);
      await container1.read(authStateProvider.future);
      final notifier1 = container1.read(authStateProvider.notifier);

      final deleteFuture1 = notifier1.deleteAccount();
      await deleteStarted1.future;

      check(
        await notifier1.loginWithCredentials(
          email: 'a@example.com',
          password: 'password123',
        ),
      ).equals(true);
      check(
        storedValues[SecureStorageKeys.customUserEmail],
      ).equals('a@example.com');
      check(
        storedValues.containsKey(SecureStorageKeys.customUserId),
      ).equals(false);

      shouldFailDelete = true;
      deleteCompleter1.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture1).equals(true);
      check(storedValues[SecureStorageKeys.accessToken]).equals(opaqueReloginA);
      verify(
        () => mockTalker.handle(
          deleteError,
          any<StackTrace?>(),
          'Failed to clear local tokens after account deletion',
        ),
      ).called(1);

      shouldFailDelete = false;
      final restartedSame = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(restartedSame.dispose);
      check(await restartedSame.read(authStateProvider.future)).equals(false);
      check(storedValues).isEmpty();
      check(
        await restartedSame
            .read(customAuthInvalidationStoreProvider)
            .isInvalidated(),
      ).equals(false);

      // 2. 別アカウント B が入力メール + クレーム無しトークンでログインし、
      //    無効化レコード残存状態で再起動しても B のセッションとメールを維持すること
      await realStorage.saveTokens(accessToken: tokenA, refreshToken: 'ref-a');
      final mockApi2 = MockApiClient();
      final deleteStarted2 = Completer<void>();
      final deleteCompleter2 = Completer<Response<void>>();
      when(
        () => mockApi2.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) {
        deleteStarted2.complete();
        return deleteCompleter2.future;
      });
      when(
        () => mockApi2.post<Map<String, dynamic>>(
          '/auth/login',
          data: any<dynamic>(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 200,
          data: {'access_token': opaqueLoginB, 'refresh_token': 'ref-op-b'},
        ),
      );

      final container2 = ProviderContainer(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi2),
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container2.dispose);
      await container2.read(authStateProvider.future);
      final notifier2 = container2.read(authStateProvider.notifier);

      final deleteFuture2 = notifier2.deleteAccount();
      await deleteStarted2.future;

      check(
        await notifier2.loginWithCredentials(
          email: 'b@example.com',
          password: 'password123',
        ),
      ).equals(true);
      check(
        await container2
            .read(customAuthInvalidationStoreProvider)
            .getInvalidationEntries(),
      ).deepEquals(const [
        (targetUserId: 'user-a', targetEmail: 'a@example.com'),
      ]);

      final restartedDifferent = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWith((ref) => realStorage),
          appSupportDirectoryReaderProvider.overrideWithValue(
            () async => tempDir,
          ),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(restartedDifferent.dispose);
      check(
        await restartedDifferent.read(authStateProvider.future),
      ).equals(true);
      check(storedValues[SecureStorageKeys.accessToken]).equals(opaqueLoginB);
      check(storedValues[SecureStorageKeys.refreshToken]).equals('ref-op-b');
      check(
        storedValues[SecureStorageKeys.customUserEmail],
      ).equals('b@example.com');
      check(
        restartedDifferent.read(authSessionLockProvider).currentSession,
      ).equals(
        TrackedAuthSession.authenticated(
          accessToken: opaqueLoginB,
          email: 'b@example.com',
        ),
      );
      check(
        await restartedDifferent
            .read(customAuthInvalidationStoreProvider)
            .isInvalidated(),
      ).equals(false);

      deleteCompleter2.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        ),
      );
      check(await deleteFuture2).equals(false);
      check(storedValues[SecureStorageKeys.accessToken]).equals(opaqueLoginB);
      check(storedValues[SecureStorageKeys.refreshToken]).equals('ref-op-b');
    });
  });
}
