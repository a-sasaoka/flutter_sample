import 'package:flutter_sample/src/core/storage/token_storage.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class FakeTokenStorage extends Mock implements TokenStorage {
  FakeTokenStorage({
    this.mockAccessToken,
    this.shouldThrowOnSave = false,
    this.shouldThrowOnClear = false,
  });

  final String? mockAccessToken;
  final bool shouldThrowOnSave;
  final bool shouldThrowOnClear;

  // 呼び出し確認用のフラグ
  bool isSaveTokensCalled = false;
  bool isClearCalled = false;

  @override
  Future<String?> getAccessToken() async => mockAccessToken;

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
  ProviderContainer createContainer(FakeTokenStorage fakeStorage) {
    final container = ProviderContainer(
      overrides: [
        // tokenStorageProvider を Fake クラスに差し替える
        tokenStorageProvider.overrideWith((ref) => fakeStorage),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AuthStateNotifier (build)', () {
    test('初期化: トークンが存在する場合、state が true になること', () async {
      // Arrange: 有効なトークンを返す Fake を作成
      final fakeStorage = FakeTokenStorage(mockAccessToken: 'valid_token');
      final container = createContainer(fakeStorage);

      // Act
      final authState = await container.read(authStateProvider.future);

      // Assert
      expect(authState, isTrue);
    });

    test('初期化: トークンがない場合、state が false になること', () async {
      // Arrange: トークンがない Fake を作成
      final fakeStorage = FakeTokenStorage();
      final container = createContainer(fakeStorage);

      // Act
      final authState = await container.read(authStateProvider.future);

      // Assert
      expect(authState, isFalse);
    });
  });

  group('AuthStateNotifier (methods)', () {
    test('login: トークンを保存し、state を true に更新すること', () async {
      // Arrange
      final fakeStorage = FakeTokenStorage();
      final container = createContainer(fakeStorage);
      final notifier = container.read(authStateProvider.notifier);

      // Act
      await notifier.login('access', 'refresh');

      // Assert
      expect(fakeStorage.isSaveTokensCalled, isTrue); // saveTokens が呼ばれたか
      expect(
        container.read(authStateProvider).value,
        isTrue,
      ); // state が true か
    });

    test('login: トークンの保存に失敗した場合、例外がスローされ state が AsyncError になること', () async {
      // Arrange
      final fakeStorage = FakeTokenStorage(shouldThrowOnSave: true);
      final container = createContainer(fakeStorage);
      final notifier = container.read(authStateProvider.notifier);

      // Act & Assert
      await expectLater(
        () => notifier.login('access', 'refresh'),
        throwsException,
      );

      // Assert
      expect(fakeStorage.isSaveTokensCalled, isTrue); // saveTokens が呼ばれたか
      expect(
        container.read(authStateProvider).hasError,
        isTrue,
      ); // state が AsyncError か
    });

    test('logout: トークンを削除し、state を false に更新すること', () async {
      // Arrange
      // ログアウト前はログイン状態 (true) だったと仮定する
      final fakeStorage = FakeTokenStorage(mockAccessToken: 'old_token');
      final container = createContainer(fakeStorage);
      final notifier = container.read(authStateProvider.notifier);

      // buildの完了を待つ
      await container.read(authStateProvider.future);

      // Act
      await notifier.logout();

      // Assert
      expect(fakeStorage.isClearCalled, isTrue); // clear が呼ばれたか
      expect(
        container.read(authStateProvider).value,
        isFalse,
      ); // state が false か
    });

    test('logout: トークンの削除に失敗した場合、例外がスローされ state が AsyncError になること', () async {
      // Arrange
      final fakeStorage = FakeTokenStorage(
        mockAccessToken: 'old_token',
        shouldThrowOnClear: true,
      );
      final container = createContainer(fakeStorage);
      final notifier = container.read(authStateProvider.notifier);

      // buildの完了を待つ
      await container.read(authStateProvider.future);

      // Act & Assert
      await expectLater(notifier.logout, throwsException);

      // Assert
      expect(fakeStorage.isClearCalled, isTrue); // clear が呼ばれたか
      expect(
        container.read(authStateProvider).hasError,
        isTrue,
      ); // state が AsyncError か
    });
  });
}
