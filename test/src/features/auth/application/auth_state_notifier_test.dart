import 'dart:async';
import 'dart:io';

import 'package:checks/checks.dart';
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

class MockTalker extends Mock implements Talker {}

class FakeTokenStorage extends Mock implements TokenStorage {
  FakeTokenStorage({
    this.mockAccessToken,
    this.mockAccessTokenFuture,
    this.shouldThrowOnSave = false,
    this.shouldThrowOnClear = false,
  });

  String? mockAccessToken;
  final Future<String?>? mockAccessTokenFuture;
  final bool shouldThrowOnSave;
  bool shouldThrowOnClear;

  // 呼び出し確認用のフラグ
  bool isSaveTokensCalled = false;
  bool isClearCalled = false;

  @override
  Future<String?> getAccessToken() async => mockAccessTokenFuture != null
      ? await mockAccessTokenFuture!
      : mockAccessToken;

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
  }

  @override
  Future<void> clear() async {
    isClearCalled = true;
    if (shouldThrowOnClear) {
      throw Exception('Failed to clear tokens');
    }
    mockAccessToken = null;
  }
}

void main() {
  late MockTalker mockTalker;
  late Directory tempDir;

  File invalidationMarkerFile() =>
      File(p.join(tempDir.path, CustomAuthInvalidationStore.markerFileName));

  setUpAll(() {
    registerFallbackValue(StackTrace.current);
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
      tempDir.deleteSync(recursive: true);
    }
  });

  /// テストごとにクリーンな ProviderContainer を作成するヘルパー
  ProviderContainer createContainer({
    FakeTokenStorage? fakeStorage,
    MockAuthRepository? mockAuthRepository,
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
      check(invalidationMarkerFile().existsSync()).equals(false);
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
      check(invalidationMarkerFile().existsSync()).equals(true);
      verify(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace?>(),
          'Failed to clear invalidated custom auth tokens on startup',
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
      check(
        container.read(authStateProvider).hasError,
      ).equals(true); // state が AsyncError か
    });

    test(
      'loginWithCredentials: 認証に成功した場合、リポジトリのloginを呼び出し、state を true に更新すること',
      () async {
        // Arrange
        final fakeStorage = FakeTokenStorage();
        final mockAuthRepository = MockAuthRepository();
        when(
          () => mockAuthRepository.login(any(), any()),
        ).thenAnswer((_) async {});
        final container = createContainer(
          fakeStorage: fakeStorage,
          mockAuthRepository: mockAuthRepository,
        );

        // buildの完了を待つ
        await container.read(authStateProvider.future);
        final notifier = container.read(authStateProvider.notifier);

        // Act
        await notifier.loginWithCredentials(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        verify(
          () => mockAuthRepository.login('test@example.com', 'password123'),
        ).called(1);
        check(container.read(authStateProvider).value).equals(true);
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
        ).thenAnswer((_) async {});

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
    test('deleteAccount: API成功時は state が AsyncData(false) になること', () async {
      final fakeStorage = FakeTokenStorage(mockAccessToken: 'valid_token');
      final mockRepo = MockAuthRepository();
      when(mockRepo.deleteAccount).thenAnswer((_) async {});

      final container = createContainer(
        fakeStorage: fakeStorage,
        mockAuthRepository: mockRepo,
      );
      await container.read(authStateProvider.future);
      final notifier = container.read(authStateProvider.notifier);

      await notifier.deleteAccount();

      verify(mockRepo.deleteAccount).called(1);
      check(container.read(authStateProvider).value).equals(false);
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
      check(invalidationMarkerFile().existsSync()).equals(true);
      await notifier.login('new_access', 'new_refresh');
      check(await store.isInvalidated()).equals(false);
      check(invalidationMarkerFile().existsSync()).equals(false);
      check(container.read(authStateProvider).value).equals(true);

      await store.markInvalidated();
      check(invalidationMarkerFile().existsSync()).equals(true);
      await notifier.logout();
      check(await store.isInvalidated()).equals(false);
      check(invalidationMarkerFile().existsSync()).equals(false);
      check(container.read(authStateProvider).value).equals(false);
    });
  });
}
