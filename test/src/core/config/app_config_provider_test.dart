import 'package:checks/checks.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/core/config/app_config_provider.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/text_scale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/core/config/theme_scheme_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MockThemeModeNotifier extends ThemeModeNotifier {
  MockThemeModeNotifier(this._mode);
  final ThemeMode _mode;
  @override
  Future<ThemeMode> build() async => _mode;
}

class MockLocaleNotifier extends LocaleNotifier {
  MockLocaleNotifier(this._locale);
  final Locale? _locale;
  @override
  Future<Locale?> build() async => _locale;
}

class MockThemeSchemeNotifier extends ThemeSchemeNotifier {
  MockThemeSchemeNotifier(this._scheme);
  final FlexScheme _scheme;
  @override
  Future<FlexScheme> build() async => _scheme;
}

class MockTextScaleNotifier extends TextScaleNotifier {
  MockTextScaleNotifier(this._scale);
  final AppTextScale _scale;
  @override
  Future<AppTextScale> build() async => _scale;
}

void main() {
  group('appConfigProvider テスト', () {
    test('ルーター、テーマ、カラースキーム、文字倍率、言語設定が正しく取得され、完全なテーマと共に返されること', () async {
      // Arrange (準備)
      final dummyRouter = GoRouter(routes: []);
      const dummyTheme = ThemeMode.dark;
      const dummyLocale = Locale('ja', 'JP');
      const dummyScheme = FlexScheme.tealM3;
      const dummyScale = AppTextScale.large;

      final container = ProviderContainer(
        overrides: [
          routerProvider.overrideWith((ref) => dummyRouter),
          themeModeProvider.overrideWith(
            () => MockThemeModeNotifier(dummyTheme),
          ),
          localeProvider.overrideWith(() => MockLocaleNotifier(dummyLocale)),
          themeSchemeProvider.overrideWith(
            () => MockThemeSchemeNotifier(dummyScheme),
          ),
          textScaleProvider.overrideWith(
            () => MockTextScaleNotifier(dummyScale),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Act (実行)
      final config = await container.read(appConfigProvider.future);

      // Assert (検証)
      check(config.router).equals(dummyRouter);
      check(config.themeMode).equals(dummyTheme);
      check(config.locale).equals(dummyLocale);
      check(config.textScaler).equals(TextScaler.linear(dummyScale.scale));
      check(
        config.lightTheme.colorScheme.primary,
      ).equals(AppTheme.light(dummyScheme).colorScheme.primary);
      check(
        config.darkTheme.colorScheme.primary,
      ).equals(AppTheme.dark(dummyScheme).colorScheme.primary);
    });
  });
}
