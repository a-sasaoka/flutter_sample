import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/user/application/user_notifier.dart';
import 'package:flutter_sample/src/features/user/application/user_search_query.dart';
import 'package:flutter_sample/src/features/user/data/user_repository.dart';
import 'package:flutter_sample/src/features/user/domain/address.dart';
import 'package:flutter_sample/src/features/user/domain/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('UserSearchQuery', () {
    test('初期状態は空文字であること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      check(container.read(userSearchQueryProvider)).equals('');
    });

    test('setQuery で更新され、clear で空文字にリセットされること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(userSearchQueryProvider.notifier).setQuery('Flutter');
      check(container.read(userSearchQueryProvider)).equals('Flutter');

      // 同一の値設定時は再代入されないことの網羅
      container.read(userSearchQueryProvider.notifier).setQuery('Flutter');
      check(container.read(userSearchQueryProvider)).equals('Flutter');

      container.read(userSearchQueryProvider.notifier).clear();
      check(container.read(userSearchQueryProvider)).equals('');
    });
  });

  group('filteredUsersProvider', () {
    const dummyAddress = Address(
      city: 'Tokyo',
      street: '123 St',
      suite: 'Apt 1',
    );

    final dummyUsers = [
      const UserModel(
        id: 1,
        name: 'Alice Johnson',
        email: 'alice@example.com',
        phone: '111-222-3333',
        website: 'alice.com',
        address: dummyAddress,
      ),
      const UserModel(
        id: 2,
        name: 'Bob Smith',
        email: 'bob@work.org',
        phone: '444-555-6666',
        website: 'bob.org',
        address: dummyAddress,
      ),
    ];

    test('検索クエリが空のときは全件を返すこと', () async {
      final expectedFetchedAt = DateTime(2026, 5, 20);
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWith(
            () => _FakeUserNotifier(dummyUsers, expectedFetchedAt),
          ),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(filteredUsersProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(userProvider.future);
      final result = container.read(filteredUsersProvider);
      check(result.value?.$1.length).equals(2);
      check(result.value?.$2).equals(expectedFetchedAt);
    });

    test('名前で大文字小文字を区別せず部分一致で絞り込めること', () async {
      final expectedFetchedAt = DateTime(2026, 5, 20);
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWith(
            () => _FakeUserNotifier(dummyUsers, expectedFetchedAt),
          ),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(filteredUsersProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(userProvider.future);
      container.read(userSearchQueryProvider.notifier).setQuery('  ALICE  ');
      final result = container.read(filteredUsersProvider);
      check(result.value?.$1.length).equals(1);
      check(result.value?.$1.first.name).equals('Alice Johnson');
      check(result.value?.$2).equals(expectedFetchedAt);
    });

    test('メールアドレスで部分一致で絞り込めること', () async {
      final expectedFetchedAt = DateTime(2026, 5, 20);
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWith(
            () => _FakeUserNotifier(dummyUsers, expectedFetchedAt),
          ),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(filteredUsersProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(userProvider.future);
      container.read(userSearchQueryProvider.notifier).setQuery('work.org');
      final result = container.read(filteredUsersProvider);
      check(result.value?.$1.length).equals(1);
      check(result.value?.$1.first.email).equals('bob@work.org');
      check(result.value?.$2).equals(expectedFetchedAt);
    });

    test('初回ローディング中は AsyncLoading になること', () {
      final completer = Completer<(List<UserModel>, DateTime?)>();
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWith(() => _AsyncUserNotifier(completer.future)),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(filteredUsersProvider, (_, _) {});
      addTearDown(sub.close);

      final result = container.read(filteredUsersProvider);
      check(result.isLoading).equals(true);
      check(result.hasValue).equals(false);
    });

    test('初回エラー発生時は AsyncError になること', () async {
      final mockRepository = MockUserRepository();
      final exception = Exception('Initial fetch error');
      when(mockRepository.fetchUsers).thenAnswer((_) async => throw exception);

      final completer = Completer<void>();
      final container = ProviderContainer(
        overrides: [userRepositoryProvider.overrideWithValue(mockRepository)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(filteredUsersProvider, (previous, next) {
        if (next.hasError && !completer.isCompleted) {
          completer.complete();
        }
      }, fireImmediately: true);
      addTearDown(sub.close);

      await completer.future.timeout(const Duration(seconds: 5));
      final result = container.read(filteredUsersProvider);
      check(result.hasError).equals(true);
      check(result.error).equals(exception);
    });
  });
}

class _AsyncUserNotifier extends UserNotifier {
  _AsyncUserNotifier(this._future);
  final Future<(List<UserModel>, DateTime?)> _future;

  @override
  Future<(List<UserModel>, DateTime?)> build() => _future;
}

class _FakeUserNotifier extends UserNotifier {
  _FakeUserNotifier(this._users, this._time);
  final List<UserModel> _users;
  final DateTime _time;

  @override
  Future<(List<UserModel>, DateTime?)> build() async => (_users, _time);
}
