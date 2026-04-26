import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// Firebase の User オブジェクトのモック
class MockUser extends Mock implements User {}

void main() {
  group('FirebaseAuthStateNotifier', () {
    test(
      'ログイン済み: authStateChangesProvider が User を返す時、state に User がセットされること',
      () async {
        // Arrange
        final mockUser = MockUser();

        final container = ProviderContainer(
          overrides: [
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockUser),
            ),
          ],
        );
        addTearDown(container.dispose);

        // 💡 修正1: listen を使って Provider を「監視状態」にし、勝手に破棄されるのを防ぐ
        container.listen(firebaseAuthStateProvider, (_, _) {});

        // 非同期データが流れて状態が同期されるまで1フレーム待つ
        await Future<void>.delayed(Duration.zero);

        // Act
        final state = container.read(firebaseAuthStateProvider);

        // Assert
        expect(state, mockUser);
      },
    );

    test(
      '未ログイン: authStateChangesProvider が null を返す時、state に null がセットされること',
      () async {
        // Arrange
        final container = ProviderContainer(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          ],
        );
        addTearDown(container.dispose);

        // 監視状態にする
        container.listen(firebaseAuthStateProvider, (_, _) {});

        await Future<void>.delayed(Duration.zero);

        // Act
        final state = container.read(firebaseAuthStateProvider);

        // Assert
        expect(state, isNull);
      },
    );

    test(
      'ロード中: authStateChangesProvider がまだ値を流していない時、state は null になること',
      () async {
        // Arrange
        final streamController = StreamController<User?>();

        final container = ProviderContainer(
          overrides: [
            authStateChangesProvider.overrideWith(
              (ref) => streamController.stream,
            ),
          ],
        );
        addTearDown(container.dispose);

        // 監視状態にする
        container.listen(firebaseAuthStateProvider, (_, _) {});

        // Act
        // まだ streamController に何も追加していない（ロード中）の状態で読み取る
        final state = container.read(firebaseAuthStateProvider);

        // Assert
        expect(state, isNull);

        // 💡 修正2: Riverpodのエラー（Bad state）を回避するため、
        // テスト終了直前にダミーの値を流して「ロード状態」を平和に終わらせる
        streamController.add(null);
        await Future<void>.delayed(Duration.zero);
        await streamController.close();
      },
    );
  });
}
