import 'package:flutter_sample/src/features/user/application/user_notifier.dart';
import 'package:flutter_sample/src/features/user/data/user_model.dart';
import 'package:flutter_sample/src/features/user/data/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// UserRepository のフェイク（確実な結果を返す本物の代替品）
class FakeUserRepository extends UserRepository {
  FakeUserRepository({this.mockResult, this.mockError});

  List<UserModel>? mockResult;
  Exception? mockError;

  @override
  dynamic build() => null;

  @override
  Future<List<UserModel>> fetchUsers() async {
    if (mockError != null) throw mockError!;
    return mockResult ?? [];
  }
}

void main() {
  /// ProviderContainer を作成するヘルパー関数
  ProviderContainer makeProviderContainer(FakeUserRepository fakeRepo) {
    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWith(() => fakeRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// テスト用の UserModel ダミーデータを生成するヘルパー関数
  /// Freezed の fromJson を使えば、Address クラスの構造を完全に知らなくても
  /// 最低限の JSON マップから安全にインスタンス化できます！
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

  group('UserNotifier Coverage 100% Test', () {
    test('【正常系】build(): 初期化時に fetchUsers が呼ばれ、AsyncData になること', () async {
      // 本物のインスタンスをダミーデータとして用意
      final dummyUsers = [createDummyUser(1), createDummyUser(2)];

      final fakeRepo = FakeUserRepository(mockResult: dummyUsers);
      final container = makeProviderContainer(fakeRepo);

      final result = await container.read(userProvider.future);

      expect(result, dummyUsers);
      final state = container.read(userProvider);
      expect(state, isA<AsyncData<List<UserModel>>>());
    });

    test('【異常系】build(): fetchUsers で例外が発生した場合、AsyncError になること', () async {
      final exception = Exception('Fetch Error');
      final fakeRepo = FakeUserRepository(mockError: exception);
      final container = makeProviderContainer(fakeRepo)
        // ダミーのリスナーを登録し、テストが終わるまでプロバイダーを「生存」させる
        ..listen(userProvider, (_, _) {});

      // AsyncError が投げられることを検証
      await expectLater(
        container.read(userProvider.future),
        throwsA(isA<Exception>()),
      );

      final state = container.read(userProvider);
      expect(state, isA<AsyncError<List<UserModel>>>());
    });

    test('【正常系】refresh(): AsyncLoading を経て、最新のデータで AsyncData になること', () async {
      final initialUsers = [createDummyUser(1)];
      final newUsers = [createDummyUser(1), createDummyUser(2)];

      final fakeRepo = FakeUserRepository(mockResult: initialUsers);
      final container = makeProviderContainer(fakeRepo);

      // 1. 初期化を待つ
      await container.read(userProvider.future);

      // 2. フェイクのリポジトリが返すデータを新しいものに差し替える
      fakeRepo.mockResult = newUsers;

      final states = <AsyncValue<List<UserModel>>>[];
      container.listen(
        userProvider,
        (_, next) => states.add(next),
      );

      // 3. refresh 実行
      await container.read(userProvider.notifier).refresh();

      // 4. Loading -> Data の遷移を検証
      expect(states.length, 2);
      expect(states[0], isA<AsyncLoading<List<UserModel>>>());
      expect(states[1], isA<AsyncData<List<UserModel>>>());

      // データが更新されているか検証
      expect(states[1].value, newUsers);
    });

    test(
      '【異常系】refresh(): 例外が発生した場合、AsyncLoading を経て AsyncError になること',
      () async {
        final fakeRepo = FakeUserRepository(mockResult: []);
        final container = makeProviderContainer(fakeRepo);

        await container.read(userProvider.future);

        // エラーを投げるように仕込む
        fakeRepo.mockError = Exception('Refresh Error');

        final states = <AsyncValue<List<UserModel>>>[];
        container.listen(
          userProvider,
          (_, next) => states.add(next),
        );

        await container.read(userProvider.notifier).refresh();

        // Loading -> Error の遷移を検証
        expect(states.length, 2);
        expect(states[0], isA<AsyncLoading<List<UserModel>>>());
        expect(states[1], isA<AsyncError<List<UserModel>>>());
      },
    );
  });
}
