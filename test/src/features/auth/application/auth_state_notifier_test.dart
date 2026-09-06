import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeTokenStorage extends Mock implements TokenStorage {
  FakeTokenStorage({
    this.mockAccessToken,
    this.mockAccessTokenFuture,
    this.shouldThrowOnSave = false,
    this.shouldThrowOnClear = false,
  });

  final String? mockAccessToken;
  final Future<String?>? mockAccessTokenFuture;
  final bool shouldThrowOnSave;
  final bool shouldThrowOnClear;

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
  }

  @override
  Future<void> clear() async {
    isClearCalled = true;
    if (shouldThrowOnClear) {
      throw Exception('Failed to clear tokens');
    }
  }
}

void main() {
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
        final mockAuthRepository = MockAuthRepository();
        when(
          () => mockAuthRepository.login(any(), any()),
        ).thenAnswer((_) async {});
        final container = createContainer(
          mockAuthRepository: mockAuthRepository,
        );
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
        check(
          container.read(authStateProvider).value,
        ).equals(true);
      },
    );

    test(
      'loginWithCredentials: 認証に失敗した場合、例外がスローされ state が AsyncError になること',
      () async {
        // Arrange
        final mockAuthRepository = MockAuthRepository();
        when(
          () => mockAuthRepository.login(any(), any()),
        ).thenThrow(Exception('Login failed'));
        final container = createContainer(
          mockAuthRepository: mockAuthRepository,
        );
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
        check(
          container.read(authStateProvider).hasError,
        ).equals(true);
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
  });
}
