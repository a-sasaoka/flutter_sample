import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('SplashStateProviderのテスト', () {
    test('初期状態が false であること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final splashState = container.read(splashStateProvider);
      check(splashState).equals(false);
    });

    test('finishSplash() を呼び出すと状態が true に変わること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期値を確認
      check(container.read(splashStateProvider)).equals(false);

      // 完了を通知
      container.read(splashStateProvider.notifier).finishSplash();

      // 変更後の値を確認
      check(container.read(splashStateProvider)).equals(true);
    });
  });
}
