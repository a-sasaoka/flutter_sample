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

  // テスト用のコンテナを作成する（ここでモックに差し替える）
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
        'geo': {
          'lat': '35.6895',
          'lng': '139.6917',
        },
      },
    });
  }

  group('UserNotifier', () {
    test('正常系: データが正しく取得でき、AsyncData になること', () async {
      // Arrange
      final dummyUsers = [createDummyUser(1)];
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => dummyUsers);

      final container = createContainer();

      // プロバイダーを起動し、自動破棄を防ぐリスナー
      final subscription = container.listen(userProvider, (_, _) {});

      // 初回は Loading
      expect(
        container.read(userProvider),
        isA<AsyncLoading<List<UserModel>>>(),
      );

      // .future には触らず、Dartの内部処理（マイクロタスク）が1周するのを待つだけ
      await Future<void>.delayed(Duration.zero);

      // Assert: 状態が AsyncData に更新されていることを確認
      final state = container.read(userProvider);
      expect(state, isA<AsyncData<List<UserModel>>>());
      expect(state.value, dummyUsers);

      // リスナーを閉じる
      subscription.close();
    });

    test('異常系: エラーが発生した場合、エラー状態になること', () async {
      // Arrange
      final exception = Exception('API Error');
      // 非同期エラーを確実に再現するため async => throw を使用
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => throw exception);

      final container = createContainer();

      // 状態の完了を待つための Completer
      final completer = Completer<void>();

      // リスナーで状態を監視し、Loading が終わった（またはエラーが出た）ら完了とする
      container.listen(
        userProvider,
        (previous, next) {
          // next.hasError: エラーを保持しているか
          // !next.isLoading: 読み込み中でないか
          if (next.hasError || !next.isLoading) {
            if (!completer.isCompleted) completer.complete();
          }
        },
        fireImmediately: true,
      );

      // Act: Completer が完了するまで待つ
      await completer.future;

      // Assert: 最終的な状態をチェック
      final state = container.read(userProvider);

      // Riverpod の状態が「エラーを保持していること」を確認
      expect(state.hasError, isTrue, reason: 'エラーを保持しているはず');
      expect(state.error, exception, reason: '投げた例外と一致するはず');
    });

    test('refresh: forceRefresh=true でデータが再取得され、状態が更新されること', () async {
      // Arrange
      final initialUsers = [createDummyUser(1)];
      final refreshedUsers = [createDummyUser(2), createDummyUser(3)];

      // 1. 初回の build() 用（引数なし）
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => initialUsers);

      // 2. refresh() 用（forceRefresh: true）
      when(
        () => mockRepository.fetchUsers(forceRefresh: true),
      ).thenAnswer((_) async => refreshedUsers);

      final container = createContainer();
      final subscription = container.listen(userProvider, (_, _) {});

      // 初回の読み込み完了を待つ
      await Future<void>.delayed(Duration.zero);
      expect(container.read(userProvider).value, initialUsers);

      // Act: refresh を実行
      await container.read(userProvider.notifier).refresh();

      // Assert: 状態が「新しいデータ」に更新されていること
      final state = container.read(userProvider);
      expect(state, isA<AsyncData<List<UserModel>>>());
      expect(state.value, refreshedUsers);

      // Repository のメソッドが、確実に `forceRefresh: true` を伴って呼ばれたことを証明
      verify(() => mockRepository.fetchUsers(forceRefresh: true)).called(1);

      subscription.close();
    });
  });
}
