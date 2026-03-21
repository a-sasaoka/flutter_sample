import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
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
        sharedPreferencesProvider.overrideWith((ref) async => mockPrefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ThemeModeNotifier テスト', () {
    test('初期化時(build): 保存されたテーマがない場合は ThemeMode.system を返すこと', () async {
      // Arrange
      when(
        () => mockPrefs.getString('theme_mode'),
      ).thenAnswer((_) async => null);

      final container = createContainer();

      // Act
      final theme = await container.read(themeModeProvider.future);

      // Assert
      expect(theme, equals(ThemeMode.system));
      verify(() => mockPrefs.getString('theme_mode')).called(1);
    });

    test(
      '初期化時(build): "dark" が保存されている場合は ThemeMode.dark を返すこと（拡張メソッドのテスト兼ねる）',
      () async {
        // Arrange
        when(
          () => mockPrefs.getString('theme_mode'),
        ).thenAnswer((_) async => 'dark');

        final container = createContainer();

        // Act
        final theme = await container.read(themeModeProvider.future);

        // Assert: _ThemeModeFromString.toThemeMode() が正しく動いているかの証明になります
        expect(theme, equals(ThemeMode.dark));
      },
    );

    test(
      '初期化時(build): 無効な文字列が保存されていた場合は初期化に失敗し、StateError(またはException)になること',
      () async {
        // Arrange
        when(
          () => mockPrefs.getString('theme_mode'),
        ).thenAnswer((_) async => 'invalid_theme');

        final container = createContainer();

        // Assert
        // Riverpodの仕様上、初期化中のエラーは dispose 時に StateError として投げられるため、
        // StateError を期待するテストに変更します。
        await expectLater(
          () => container.read(themeModeProvider.future),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('set(): 任意のテーマを渡すと状態が更新され、ストレージに保存されること（拡張メソッドのテスト兼ねる）', () async {
      // Arrange
      when(
        () => mockPrefs.getString('theme_mode'),
      ).thenAnswer((_) async => null);
      when(
        () => mockPrefs.setString('theme_mode', 'light'),
      ).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(themeModeProvider.future); // 初期化完了を待つ

      // Act
      final notifier = container.read(themeModeProvider.notifier);
      await notifier.set(ThemeMode.light);

      // Assert
      // 1. 状態が即時反映(AsyncData)されているか
      expect(
        container.read(themeModeProvider).value,
        equals(ThemeMode.light),
      );
      // 2. _ThemeModeExt.valeu 経由で 'light' という文字列に変換されて保存されたか
      verify(() => mockPrefs.setString('theme_mode', 'light')).called(1);
    });

    test('toggleLightDark(): 現在が system の場合は dark に切り替わること', () async {
      // Arrange
      when(
        () => mockPrefs.getString('theme_mode'),
      ).thenAnswer((_) async => null); // systemスタート
      when(
        () => mockPrefs.setString('theme_mode', 'dark'),
      ).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(themeModeProvider.future);

      // Act
      final notifier = container.read(themeModeProvider.notifier);
      await notifier.toggleLightDark();

      // Assert
      expect(
        container.read(themeModeProvider).value,
        equals(ThemeMode.dark),
      );
      verify(() => mockPrefs.setString('theme_mode', 'dark')).called(1);
    });

    test('toggleLightDark(): 現在が dark の場合は light に切り替わること', () async {
      // Arrange
      when(
        () => mockPrefs.getString('theme_mode'),
      ).thenAnswer((_) async => 'dark'); // darkスタート
      when(
        () => mockPrefs.setString('theme_mode', 'light'),
      ).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(themeModeProvider.future);

      // Act
      final notifier = container.read(themeModeProvider.notifier);
      await notifier.toggleLightDark();

      // Assert
      expect(
        container.read(themeModeProvider).value,
        equals(ThemeMode.light),
      );
      verify(() => mockPrefs.setString('theme_mode', 'light')).called(1);
    });
  });
}
