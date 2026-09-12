import 'package:checks/checks.dart';
import 'package:flutter_sample/src/app/constants/storage_keys.dart';
import 'package:flutter_sample/src/core/config/text_scale_provider.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferencesAsyncのモック
class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  late MockSharedPreferencesAsync mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
  });

  /// テスト用のProviderContainerを作成するヘルパー
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('TextScaleNotifier テスト', () {
    test(
      '初期化時(build): 保存された倍率設定がない場合は defaultScale (AppTextScale.normal) を返すこと',
      () async {
        // Arrange
        when(
          () => mockPrefs.getString(SharedPrefKeys.textScale),
        ).thenAnswer((_) async => null);

        final container = createContainer();

        // Act
        final scale = await container.read(textScaleProvider.future);

        // Assert
        check(scale).equals(AppTextScale.normal);
        verify(() => mockPrefs.getString(SharedPrefKeys.textScale)).called(1);
      },
    );

    test(
      '初期化時(build): "small" が保存されている場合は AppTextScale.small を返すこと',
      () async {
        // Arrange
        when(
          () => mockPrefs.getString(SharedPrefKeys.textScale),
        ).thenAnswer((_) async => 'small');

        final container = createContainer();

        // Act
        final scale = await container.read(textScaleProvider.future);

        // Assert
        check(scale).equals(AppTextScale.small);
        check(scale.scale).equals(0.85);
      },
    );

    test(
      '初期化時(build): "large" が保存されている場合は AppTextScale.large を返すこと',
      () async {
        // Arrange
        when(
          () => mockPrefs.getString(SharedPrefKeys.textScale),
        ).thenAnswer((_) async => 'large');

        final container = createContainer();

        // Act
        final scale = await container.read(textScaleProvider.future);

        // Assert
        check(scale).equals(AppTextScale.large);
        check(scale.scale).equals(1.15);
      },
    );

    test(
      '初期化時(build): 無効な文字列が保存されていた場合は defaultScale を返すこと',
      () async {
        // Arrange
        when(
          () => mockPrefs.getString(SharedPrefKeys.textScale),
        ).thenAnswer((_) async => 'invalid_scale');

        final container = createContainer();

        // Act
        final scale = await container.read(textScaleProvider.future);

        // Assert
        check(scale).equals(AppTextScale.normal);
      },
    );

    test('setScale(): 任意の倍率を渡すと状態が更新され、ストレージに保存されること', () async {
      // Arrange
      when(
        () => mockPrefs.getString(SharedPrefKeys.textScale),
      ).thenAnswer((_) async => null);
      when(
        () => mockPrefs.setString(SharedPrefKeys.textScale, 'large'),
      ).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(textScaleProvider.future);

      // Act
      await container
          .read(textScaleProvider.notifier)
          .setScale(AppTextScale.large);

      // Assert
      final state = container.read(textScaleProvider);
      check(state).isA<AsyncData<AppTextScale>>().which(
        (data) => data.has((d) => d.value, 'value').equals(AppTextScale.large),
      );

      verify(
        () => mockPrefs.setString(SharedPrefKeys.textScale, 'large'),
      ).called(1);
    });
  });
}
