import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/config/app_config_provider.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/config/theme_mode_provider.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'settings_screen_test.dart';

void main() {
  group('SettingsScreen Golden Tests', () {
    late MockFirebaseAuthRepository mockAuthRepo;
    late MockAppLocalizations mockL10n;
    late FakeThemeModeNotifier fakeThemeModeNotifier;
    late FakeLocaleNotifier fakeLocaleNotifier;

    setUp(() {
      mockAuthRepo = MockFirebaseAuthRepository();
      mockL10n = MockAppLocalizations();
      fakeThemeModeNotifier = FakeThemeModeNotifier();
      fakeLocaleNotifier = FakeLocaleNotifier();

      when(() => mockL10n.settingsTitle).thenReturn('設定');
      when(() => mockL10n.settingsThemeSection).thenReturn('テーマ設定');
      when(() => mockL10n.settingsThemeSystem).thenReturn('システム');
      when(() => mockL10n.settingsThemeLight).thenReturn('ライト');
      when(() => mockL10n.settingsThemeDark).thenReturn('ダーク');
      when(() => mockL10n.settingsThemeToggle).thenReturn('ダークモードにする');
      when(() => mockL10n.settingsLocaleSection).thenReturn('言語設定');
      when(() => mockL10n.settingsLocaleSystem).thenReturn('システム依存');
      when(() => mockL10n.settingsLocaleJa).thenReturn('日本語');
      when(() => mockL10n.settingsLocaleEn).thenReturn('英語');
      when(() => mockL10n.hello).thenReturn('こんにちは！');
      when(() => mockL10n.logout).thenReturn('ログアウト');
    });

    Widget buildSettingsForGolden() {
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          appConfigProvider.overrideWith((ref) async {
            return (
              locale: const Locale('ja'),
              router: router,
              theme: ThemeMode.light,
            );
          }),
          envConfigProvider.overrideWithValue(
            const EnvConfigState(
              baseUrl: 'https://test.example.com',
              aiModel: 'test-model',
              connectTimeout: 10,
              receiveTimeout: 15,
              sendTimeout: 10,
              useFirebaseAuth: true,
            ),
          ),
          firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
          themeModeProvider.overrideWith(() => fakeThemeModeNotifier),
          localeProvider.overrideWith(() => fakeLocaleNotifier),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light().copyWith(
            textTheme: AppTheme.light().textTheme.apply(
              fontFamily: 'NotoSansJP',
            ),
          ),
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
      'SettingsScreen の描画',
      fileName: 'settings_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default State',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildSettingsForGolden(),
            ),
          ),
        ],
      ),
    );
  });
}
