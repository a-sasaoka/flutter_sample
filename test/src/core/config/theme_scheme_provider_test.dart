import 'package:checks/checks.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_sample/src/app/constants/storage_keys.dart';
import 'package:flutter_sample/src/core/config/theme_scheme_provider.dart';
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

  group('ThemeSchemeNotifier テスト', () {
    test(
      '初期化時(build): 保存されたスキームがない場合は defaultScheme (indigoM3) を返すこと',
      () async {
        // Arrange
        when(
          () => mockPrefs.getString(SharedPrefKeys.themeScheme),
        ).thenAnswer((_) async => null);

        final container = createContainer();

        // Act
        final scheme = await container.read(themeSchemeProvider.future);

        // Assert
        check(scheme).equals(FlexScheme.indigoM3);
        verify(() => mockPrefs.getString(SharedPrefKeys.themeScheme)).called(1);
      },
    );

    test(
      '初期化時(build): "tealM3" が保存されている場合は FlexScheme.tealM3 を返すこと',
      () async {
        // Arrange
        when(
          () => mockPrefs.getString(SharedPrefKeys.themeScheme),
        ).thenAnswer((_) async => 'tealM3');

        final container = createContainer();

        // Act
        final scheme = await container.read(themeSchemeProvider.future);

        // Assert
        check(scheme).equals(FlexScheme.tealM3);
      },
    );

    test(
      '初期化時(build): 無効な文字列が保存されていた場合は defaultScheme を返すこと',
      () async {
        // Arrange
        when(
          () => mockPrefs.getString(SharedPrefKeys.themeScheme),
        ).thenAnswer((_) async => 'invalid_scheme');

        final container = createContainer();

        // Act
        final scheme = await container.read(themeSchemeProvider.future);

        // Assert
        check(scheme).equals(FlexScheme.indigoM3);
      },
    );

    test('setScheme(): 任意のカラースキームを渡すと状態が更新され、ストレージに保存されること', () async {
      // Arrange
      when(
        () => mockPrefs.getString(SharedPrefKeys.themeScheme),
      ).thenAnswer((_) async => null);
      when(
        () => mockPrefs.setString(SharedPrefKeys.themeScheme, 'orangeM3'),
      ).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(themeSchemeProvider.future);

      // Act
      final notifier = container.read(themeSchemeProvider.notifier);
      await notifier.setScheme(FlexScheme.orangeM3);

      // Assert
      check(
        container.read(themeSchemeProvider).value,
      ).equals(FlexScheme.orangeM3);
      verify(
        () => mockPrefs.setString(SharedPrefKeys.themeScheme, 'orangeM3'),
      ).called(1);
    });
  });
}
