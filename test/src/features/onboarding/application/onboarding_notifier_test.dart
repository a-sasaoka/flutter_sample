import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  late MockSharedPreferencesAsync mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
  });

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
      when(
        () => mockPrefs.getBool('onboarding_completed'),
      ).thenAnswer((_) async => null);

      final container = createContainer();

      final result = await container.read(onboardingProvider.future);
      check(result).isFalse();
      verify(() => mockPrefs.getBool('onboarding_completed')).called(1);
    });

    test('初期化時(build): 完了済み(true)が保存されている場合は true を返すこと', () async {
      when(
        () => mockPrefs.getBool('onboarding_completed'),
      ).thenAnswer((_) async => true);

      final container = createContainer();

      final result = await container.read(onboardingProvider.future);
      check(result).isTrue();
    });

    test('complete(): 完了処理を実行すると true を保存し、状態が更新されること', () async {
      when(
        () => mockPrefs.getBool('onboarding_completed'),
      ).thenAnswer((_) async => false);
      when(
        () => mockPrefs.setBool('onboarding_completed', true),
      ).thenAnswer((_) async {});

      final container = createContainer();

      // 最初は false
      await container.read(onboardingProvider.future);

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
