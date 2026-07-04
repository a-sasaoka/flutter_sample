import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/widgets/widgets_test_helper.dart';
import '../onboarding_test_helper.dart';

void main() {
  group('OnboardingScreen Golden Tests', () {
    late MockAppLocalizations mockL10n;
    late MockSharedPreferencesAsync mockPrefs;

    setUp(() {
      mockL10n = setupMockL10n();
      mockPrefs = setupMockPrefs();
    });

    Widget buildOnboardingForGolden({required ThemeMode themeMode}) {
      final isDark = themeMode == ThemeMode.dark;

      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
        child: MaterialApp(
          theme: isDark
              ? AppTheme.dark().copyWith(
                  textTheme: AppTheme.dark().textTheme.apply(
                    fontFamily: 'NotoSansJP',
                  ),
                )
              : AppTheme.light().copyWith(
                  textTheme: AppTheme.light().textTheme.apply(
                    fontFamily: 'NotoSansJP',
                  ),
                ),
          themeMode: themeMode,
          localizationsDelegates: [
            MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const OnboardingScreen(),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // alchemistのgoldenTestは非同期処理ですが、テスト定義内で直接呼び出すため discarded_futures を無視します。
    // ignore: discarded_futures
    goldenTest(
      'OnboardingScreen の描画 (初期画面)',
      fileName: 'onboarding_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Initial Slide - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildOnboardingForGolden(themeMode: ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'Initial Slide - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildOnboardingForGolden(themeMode: ThemeMode.dark),
            ),
          ),
        ],
      ),
    );
  });
}
