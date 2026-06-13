import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../onboarding_test_helper.dart';

void main() {
  late MockSharedPreferencesAsync mockPrefs;

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('OnboardingNotifier テスト', () {
    test('初期化時(build): 保存されたフラグがない場合は false を返すこと', () async {
      mockPrefs = setupMockPrefs();

      final container = createContainer();

      final result = await container.read(onboardingProvider.future);
      check(result).isFalse();
      verify(() => mockPrefs.getBool('onboarding_completed')).called(1);
    });

    test('初期化時(build): 完了済み(true)が保存されている場合は true を返すこと', () async {
      mockPrefs = setupMockPrefs(completed: true);

      final container = createContainer();

      final result = await container.read(onboardingProvider.future);
      check(result).isTrue();
      verify(() => mockPrefs.getBool('onboarding_completed')).called(1);
    });

    test('complete(): 完了処理を実行すると true を保存し、状態が更新されること', () async {
      mockPrefs = setupMockPrefs();

      final container = createContainer();

      // 最初は false であることを確認
      final initialState = await container.read(onboardingProvider.future);
      check(initialState).isNotNull().isFalse();

      final notifier = container.read(onboardingProvider.notifier);

      // オートディスポーズなプロバイダーのロード中の破棄を防ぐため、Actの直前で listen を開始
      container.listen(onboardingProvider, (_, _) {});

      await notifier.complete();

      final state = container.read(onboardingProvider).value;
      check(state).isNotNull().isTrue();
      verify(() => mockPrefs.setBool('onboarding_completed', true)).called(1);
    });
  });
}
