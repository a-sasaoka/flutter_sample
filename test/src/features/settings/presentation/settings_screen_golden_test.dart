import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/text_scale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/core/config/theme_scheme_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'settings_screen_test.dart';

void main() {
  group('SettingsScreen Golden Tests', () {
    late MockAuthService mockAuthService;
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockAuthService = MockAuthService();
      mockL10n = MockAppLocalizations();

      when(() => mockL10n.settingsTitle).thenReturn('設定');
      when(() => mockL10n.profileTitle).thenReturn('プロフィール');
      when(() => mockL10n.settingsThemeSection).thenReturn('テーマ設定');
      when(() => mockL10n.settingsThemeSystem).thenReturn('システム');
      when(() => mockL10n.settingsThemeLight).thenReturn('ライト');
      when(() => mockL10n.settingsThemeDark).thenReturn('ダーク');
      when(() => mockL10n.settingsThemeToggle).thenReturn('ダークモードにする');
      when(() => mockL10n.settingsColorSection).thenReturn('テーマカラー設定');
      when(() => mockL10n.settingsColorIndigo).thenReturn('インディゴ');
      when(() => mockL10n.settingsColorTeal).thenReturn('ティール');
      when(() => mockL10n.settingsColorOrange).thenReturn('オレンジ');
      when(() => mockL10n.settingsColorPink).thenReturn('ピンク');
      when(() => mockL10n.settingsTextScaleSection).thenReturn('文字サイズ設定');
      when(() => mockL10n.settingsTextScaleSmall).thenReturn('小');
      when(() => mockL10n.settingsTextScaleNormal).thenReturn('標準');
      when(() => mockL10n.settingsTextScaleLarge).thenReturn('大');
      when(
        () => mockL10n.settingsTextScalePreview,
      ).thenReturn('文字サイズのプレビュー表示です');
      when(() => mockL10n.settingsLocaleSection).thenReturn('言語設定');
      when(() => mockL10n.settingsLocaleSystem).thenReturn('システム依存');
      when(() => mockL10n.settingsLocaleJa).thenReturn('日本語');
      when(() => mockL10n.settingsLocaleEn).thenReturn('英語');
      when(() => mockL10n.hello).thenReturn('こんにちは！');
      when(() => mockL10n.logout).thenReturn('ログアウト');
      when(() => mockL10n.settingsPreview).thenReturn('プレビュー');
      when(() => mockL10n.errorOccurred).thenReturn('エラーが発生しました');
    });

    Widget buildSettingsForGolden({required ThemeMode themeMode}) {
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      );

      final isDark = themeMode == ThemeMode.dark;

      // 💡 同一インスタンスが複数のProviderScopeで再利用されて
      // マウント例外 (Already mounted) が発生するのを防ぐため、
      // 呼び出しごとに新しく notifier をインスタンス化します。
      final fakeThemeSchemeNotifier = FakeThemeSchemeNotifier();
      final fakeTextScaleNotifier = FakeTextScaleNotifier();
      final fakeThemeNotifier = FakeThemeModeNotifier(themeMode);
      final fakeLocale = FakeLocaleNotifier(const Locale('ja'));

      final baseTheme = isDark ? AppTheme.dark() : AppTheme.light();
      final goldenTheme = baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(fontFamily: 'NotoSansJP'),
        primaryTextTheme: baseTheme.primaryTextTheme.apply(
          fontFamily: 'NotoSansJP',
        ),
        chipTheme: baseTheme.chipTheme.copyWith(
          labelStyle:
              baseTheme.chipTheme.labelStyle?.copyWith(
                fontFamily: 'NotoSansJP',
              ) ??
              const TextStyle(fontFamily: 'NotoSansJP'),
          secondaryLabelStyle:
              baseTheme.chipTheme.secondaryLabelStyle?.copyWith(
                fontFamily: 'NotoSansJP',
              ) ??
              const TextStyle(fontFamily: 'NotoSansJP'),
        ),
      );

      return ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(
            const EnvConfigState(
              baseUrl: 'https://test.example.com',
              imageBaseUrl: defaultImageBaseUrl,
              aiModel: 'test-model',
              connectTimeout: 10,
              receiveTimeout: 15,
              sendTimeout: 10,
              useFirebaseAuth: true,
              useAgentPlatform: true,
            ),
          ),
          isAuthenticatedProvider.overrideWithValue(true),
          authServiceProvider.overrideWithValue(mockAuthService),
          themeSchemeProvider.overrideWith(() => fakeThemeSchemeNotifier),
          textScaleProvider.overrideWith(() => fakeTextScaleNotifier),
          themeModeProvider.overrideWith(() => fakeThemeNotifier),
          localeProvider.overrideWith(() => fakeLocale),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: goldenTheme,
          themeMode: themeMode,
          localizationsDelegates: [
            MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // ignore: discarded_futures, testing framework registers tests synchronously
    goldenTest(
      'SettingsScreen の描画 (ライト/ダークモード)',
      fileName: 'settings_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 1180,
              child: buildSettingsForGolden(themeMode: ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 1180,
              child: buildSettingsForGolden(themeMode: ThemeMode.dark),
            ),
          ),
        ],
      ),
    );
  });
}
