import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/utils/jwt_utils.dart';
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

class MockAuthRepository extends Mock implements AuthRepository {}

class MockApiClient extends Mock implements ApiClient {}

class MockTalker extends Mock implements Talker {}

class MockCustomAuthInvalidationStore extends Mock
    implements CustomAuthInvalidationStore {}

String _buildJwt({String? sub, String? email}) {
  final header = base64Url.encode(
    utf8.encode(jsonEncode({'alg': 'none', 'typ': 'JWT'})),
  );
  final payload = base64Url.encode(
    utf8.encode(jsonEncode(<String, Object?>{'sub': ?sub, 'email': ?email})),
  );
  return '$header.$payload.sig';
}

class FakeTokenStorage extends Mock implements TokenStorage {
  FakeTokenStorage({
    this.mockAccessToken,
    this.mockAccessTokenFuture,
    this.currentUserId,
    this.shouldThrowOnSave = false,
    this.shouldThrowOnClear = false,
    this.onSaveTokens,
  });

  String? mockAccessToken;
  final Future<String?>? mockAccessTokenFuture;
  String? currentUserId;
  final bool shouldThrowOnSave;
  bool shouldThrowOnClear;
  Future<void> Function(String accessToken, String refreshToken)? onSaveTokens;

  // 呼び出し確認用のフラグ
  bool isSaveTokensCalled = false;
  bool isClearCalled = false;

  @override
  Future<String?> getAccessToken() async => mockAccessTokenFuture != null
      ? await mockAccessTokenFuture!
      : mockAccessToken;

  @override
  Future<String?> getUserId() async {
    if (currentUserId != null) {
      return currentUserId;
    }
    final token = await getAccessToken();
    return token != null ? JwtUtils.getUserId(token) : null;
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    isSaveTokensCalled = true;
    if (shouldThrowOnSave) {
      throw Exception('Failed to save tokens');
    }
    mockAccessToken = accessToken;
    await onSaveTokens?.call(accessToken, refreshToken);
  }

  @override
  Future<void> clear() async {
    isClearCalled = true;
    if (shouldThrowOnClear) {
      throw Exception('Failed to clear tokens');
    }
    currentUserId = null;
    mockAccessToken = null;
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
      when(mockStore.getInvalidationState).thenAnswer(
        (_) async => (
          isInvalidated: true,
          targetUserId: 'user-a',
          targetEmail: 'a@example.com',
        ),
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
      verify(mockStore.getInvalidationState).called(1);
      verify(mockStore.clearInvalidated).called(1);
      verify(
        () => mockTalker.handle(
          clearError,
          any<StackTrace?>(),
          'Failed to clear obsolete custom auth invalidation flag on startup',
        ),
      ).called(1);
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
    });

    test('login: 無効化状態の確認・解除に失敗した場合は saveTokens を呼ばず資格情報を保存しないこと', () async {
      final fakeStorage = FakeTokenStorage();
      invalidationDbFile().writeAsStringSync('invalid sqlite bytes');
      final container = createContainer(fakeStorage: fakeStorage);
      final notifier = container.read(authStateProvider.notifier);

      await check(notifier.login('new-access', 'new-refresh')).throws<Object>();

      check(fakeStorage.isSaveTokensCalled).equals(false);
      check(fakeStorage.mockAccessToken).isNull();
      check(container.read(authStateProvider).hasError).equals(true);
    });

    test(
      'loginWithCredentials: 認証に成功した場合、リポジトリのloginを呼び出し、state を true に更新すること',
      () async {
        // Arrange
        final fakeStorage = FakeTokenStorage();
        final mockAuthRepository = MockAuthRepository();
        when(
          () => mockAuthRepository.login(any(), any()),
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
          () => mockAuthRepository.login('test@example.com', 'password123'),
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
          () => mockAuthRepository.login(any(), any()),
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
          () => mockAuthRepository.login(any(), any()),
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
          () => mockAuthRepository.login('test@example.com', 'password123'),
        ).called(1);
        check(container.read(authStateProvider).hasError).equals(true);
      },
    );

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
          () => mockAuthRepository.login(any(), any()),
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
        verifyNever(() => mockAuthRepository.login(any(), any()));

        // 遅延していた初期化を完了させる（保存されたトークンはなし = false）
        tokenCompleter.complete(null);

        // ログイン処理の完了を待機
        await loginFuture;

        // Assert: ログインAPIが呼ばれ、初期化結果で上書きされずに true になっていること
        verify(
          () => mockAuthRepository.login('test@example.com', 'password123'),
        ).called(1);
        check(container.read(authStateProvider).value).equals(true);
      },
    );

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

    test('実AuthRepository連携: サーバー削除確定後にトークン消去と無効化DB参照/更新が '
        'ともに失敗しても退会自体は失敗扱いにせず state=false と true 返却で完了すること', () async {
      final tokenA = _buildJwt(sub: 'user-a', email: 'a@example.com');
      final fakeStorage = FakeTokenStorage(mockAccessToken: tokenA);
      final mockApi = MockApiClient();
      when(
        () => mockApi.delete<void>(
          '/auth/account',
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) async {
        // 削除確定直後に端末ストレージと無効化DBがともに読み書き不能になった状態を模擬
        fakeStorage.shouldThrowOnClear = true;
        Process.runSync('chmod', ['444', invalidationDbFile().path]);
        Process.runSync('chmod', ['555', tempDir.path]);
        return Response<void>(
          requestOptions: RequestOptions(path: '/auth/account'),
          statusCode: 200,
        );
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

      final result = await notifier.deleteAccount();

      check(result).equals(true);
      check(container.read(authStateProvider).value).equals(false);
      check(container.read(authStateProvider).hasError).equals(false);
      verify(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace?>(),
          'Failed to clear local tokens after account deletion',
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
  });
}
