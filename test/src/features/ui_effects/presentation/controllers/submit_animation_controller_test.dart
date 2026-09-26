import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/ui_effects/presentation/controllers/submit_animation_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('SubmitAnimationController Tests', () {
    test('初期状態は SubmitStatus.idle であること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(submitAnimationControllerProvider);
      check(state).equals(SubmitStatus.idle);
    });

    test('submit() 呼び出しで idle -> loading -> success に遷移すること', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final states = <SubmitStatus>[];
      container.listen(
        submitAnimationControllerProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );

      final notifier = container.read(
        submitAnimationControllerProvider.notifier,
      );

      // Act
      await notifier.submit(duration: const Duration(milliseconds: 50));

      // Assert
      check(states).deepEquals([
        SubmitStatus.idle,
        SubmitStatus.loading,
        SubmitStatus.success,
      ]);
    });

    test('多重タップ時、待機中以外は submit() がガードされて無視されること', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final states = <SubmitStatus>[];
      container.listen(
        submitAnimationControllerProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );

      final notifier = container.read(
        submitAnimationControllerProvider.notifier,
      );

      // 1回目のsubmit（少し長めの時間）
      final future1 = notifier.submit(
        duration: const Duration(milliseconds: 100),
      );

      // loading中の2回目のsubmit呼び出し（ガードされる）
      final future2 = notifier.submit(
        duration: const Duration(milliseconds: 100),
      );

      await Future.wait([future1, future2]);

      // loadingが2回連続で追加されたりせず、正常に1回のみ処理される
      check(states).deepEquals([
        SubmitStatus.idle,
        SubmitStatus.loading,
        SubmitStatus.success,
      ]);
    });

    test('isSuccess: false の場合、loading -> error に遷移すること', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final states = <SubmitStatus>[];
      container.listen(
        submitAnimationControllerProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );

      final notifier = container.read(
        submitAnimationControllerProvider.notifier,
      );

      // Act
      await notifier.submit(
        duration: const Duration(milliseconds: 50),
        isSuccess: false,
      );

      // Assert
      check(states).deepEquals([
        SubmitStatus.idle,
        SubmitStatus.loading,
        SubmitStatus.error,
      ]);
    });

    test('reset() を呼ぶと SubmitStatus.idle に戻ること', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // AutoDisposeによる予期せぬ破棄を防ぐため監視を開始
      container.listen(submitAnimationControllerProvider, (_, _) {});

      final notifier = container.read(
        submitAnimationControllerProvider.notifier,
      );
      await notifier.submit(
        duration: const Duration(milliseconds: 50),
        isSuccess: false,
      );

      check(
        container.read(submitAnimationControllerProvider),
      ).equals(SubmitStatus.error);

      // Act
      notifier.reset();

      // Assert
      check(
        container.read(submitAnimationControllerProvider),
      ).equals(SubmitStatus.idle);
    });

    test('task 実行中に Exception が発生した場合、loading -> error に遷移すること', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final states = <SubmitStatus>[];
      container.listen(
        submitAnimationControllerProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );

      final notifier = container.read(
        submitAnimationControllerProvider.notifier,
      );

      // Act
      await notifier.submit(task: () async => throw Exception('Network error'));

      // Assert
      check(states).deepEquals([
        SubmitStatus.idle,
        SubmitStatus.loading,
        SubmitStatus.error,
      ]);
    });

    test('SubmitStatus.error の状態から再度 submit() を呼び出して再試行できること', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final states = <SubmitStatus>[];
      container.listen(
        submitAnimationControllerProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );

      final notifier = container.read(
        submitAnimationControllerProvider.notifier,
      );

      // 1回目：エラーで終了
      await notifier.submit(
        duration: const Duration(milliseconds: 30),
        isSuccess: false,
      );
      check(
        container.read(submitAnimationControllerProvider),
      ).equals(SubmitStatus.error);

      // 2回目：エラー状態から再試行して成功
      await notifier.submit(duration: const Duration(milliseconds: 30));

      check(states).deepEquals([
        SubmitStatus.idle,
        SubmitStatus.loading,
        SubmitStatus.error,
        SubmitStatus.loading,
        SubmitStatus.success,
      ]);
    });
  });
}
