import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockUser extends Mock implements User {}

// FirebaseAuthRepository の Fake クラスを作成する
// extends を使うことで Riverpod の内部状態を維持しつつ、テスト用に挙動を乗っ取ります。
class FakeFirebaseAuthRepository extends FirebaseAuthRepository {
  FakeFirebaseAuthRepository(this._initialState);

  final User? _initialState;

  @override
  User? build() {
    return _initialState;
  }

  // テスト用に外から状態 (User?) を変更するためのヘルパーメソッド
  // ignore: use_setters_to_change_properties
  void updateUser(User? user) {
    state = user;
  }
}

void main() {
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser();
  });

  group('FirebaseAuthStateNotifier', () {
    test('初期化: リポジトリの初期状態が null の場合、state も null になること', () {
      final container = ProviderContainer(
        overrides: [
          // 引数なしの () => Fake... という形で override する
          firebaseAuthRepositoryProvider.overrideWith(
            () => FakeFirebaseAuthRepository(null),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(firebaseAuthStateProvider);

      expect(state, isNull);
    });

    test('初期化: リポジトリの初期状態が User の場合、state も User になること', () {
      final container = ProviderContainer(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWith(
            () => FakeFirebaseAuthRepository(mockUser),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(firebaseAuthStateProvider);

      expect(state, mockUser);
    });

    test(
      '状態変化: firebaseAuthRepositoryProvider が更新されると、listen して state も同期されること',
      () {
        // Arrange: 最初は未ログイン (null) 状態で Fake を作成
        final fakeRepo = FakeFirebaseAuthRepository(null);
        final container = ProviderContainer(
          overrides: [
            firebaseAuthRepositoryProvider.overrideWith(() => fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        // 1. 初回読み込み (この時点で build 内の ref.listen が登録される)
        var state = container.read(firebaseAuthStateProvider);
        expect(state, isNull);

        // 2. Act: リポジトリ側の状態を MockUser (ログイン状態) に更新する
        fakeRepo.updateUser(mockUser);

        // 3. Assert: listen が発火し、Notifier の状態も自動的に同期されているか確認
        state = container.read(firebaseAuthStateProvider);
        expect(state, mockUser);

        // 4. Act: リポジトリ側が再度ログアウト (null) したと仮定する
        fakeRepo.updateUser(null);

        // 5. Assert: 再度同期されているか
        state = container.read(firebaseAuthStateProvider);
        expect(state, isNull);
      },
    );
  });
}
