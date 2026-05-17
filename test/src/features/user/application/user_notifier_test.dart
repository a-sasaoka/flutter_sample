import 'dart:async';

import 'package:flutter_sample/src/features/user/application/user_notifier.dart';
import 'package:flutter_sample/src/features/user/data/user_repository.dart';
import 'package:flutter_sample/src/features/user/domain/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モッククラス ---
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
  });

  // テスト用のコンテナを作成する
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  // ダミーデータ生成ヘルパー
  UserModel createDummyUser(int id) {
    return UserModel.fromJson({
      'id': id,
      'name': 'Test User $id',
      'email': 'test$id@example.com',
      'phone': '123-456-7890',
      'website': 'https://example.com',
      'address': {
        'street': 'Test Street',
        'suite': 'Suite $id',
        'city': 'Tokyo',
        'zipcode': '100-0000',
        'geo': {'lat': '35.6895', 'lng': '139.6917'},
      },
    });
  }

  group('UserNotifier', () {
    test('正常系: データが正しく取得でき、AsyncData になること', () async {
      // Arrange
      final dummyUsers = [createDummyUser(1)];
      final dummyTimestamp = DateTime(2026, 5, 17, 10);
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => (dummyUsers, dummyTimestamp));

      final container = createContainer();
      final completer = Completer<void>();

      // プロバイダーを監視し、完了を待つ
      container.listen(userProvider, (prev, next) {
        if (!next.isLoading && !completer.isCompleted) {
          completer.complete();
        }
      }, fireImmediately: true);

      await completer.future.timeout(const Duration(seconds: 5));

      // Assert
      final state = container.read(userProvider);
      expect(
        state,
        isA<AsyncData<(List<UserModel>, DateTime?)>>(),
      );
      expect(state.value?.$1, dummyUsers);
      expect(state.value?.$2, dummyTimestamp);
    });

    test('異常系: エラーが発生した場合、エラー状態を保持すること', () async {
      // Arrange
      final exception = Exception('API Error');
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => throw exception);

      final container = createContainer();
      final completer = Completer<void>();

      // エラーが発生するまで監視
      container.listen(userProvider, (prev, next) {
        if (next.hasError && !completer.isCompleted) {
          completer.complete();
        }
      }, fireImmediately: true);

      // Act: エラー状態への遷移を待機
      await completer.future.timeout(const Duration(seconds: 5));

      // Assert
      final state = container.read(userProvider);
      expect(state.hasError, isTrue);
      expect(state.error, exception);
    });

    test('refresh: forceRefresh=true でデータが再取得され、状態が更新されること', () async {
      // Arrange
      final initialUsers = [createDummyUser(1)];
      final initialTimestamp = DateTime(2026, 5, 17, 10);
      final refreshedUsers = [createDummyUser(2), createDummyUser(3)];
      final refreshedTimestamp = DateTime(2026, 5, 17, 11);

      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => (initialUsers, initialTimestamp));
      when(
        () => mockRepository.fetchUsers(forceRefresh: true),
      ).thenAnswer((_) async => (refreshedUsers, refreshedTimestamp));

      final container = createContainer();
      final completer = Completer<void>();
      container.listen(userProvider, (prev, next) {
        if (!next.isLoading && !completer.isCompleted) completer.complete();
      }, fireImmediately: true);

      // 初期ロード完了を待機
      await completer.future.timeout(const Duration(seconds: 5));

      // Act: refresh を実行
      await container.read(userProvider.notifier).refresh();

      // Assert
      final state = container.read(userProvider);
      expect(
        state,
        isA<AsyncData<(List<UserModel>, DateTime?)>>(),
      );
      expect(state.value?.$1, refreshedUsers);
      expect(state.value?.$2, refreshedTimestamp);
    });
  });
}
