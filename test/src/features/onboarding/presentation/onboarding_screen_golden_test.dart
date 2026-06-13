import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../../core/widgets/widgets_test_helper.dart';
import '../application/onboarding_notifier_test.dart';

void main() {
  group('OnboardingScreen Golden Tests', () {
    late MockAppLocalizations mockL10n;
    late MockSharedPreferencesAsync mockPrefs;

    setUp(() {
      mockL10n = MockAppLocalizations();
      when(() => mockL10n.onboardingSkip).thenReturn('Skip');
      when(() => mockL10n.onboardingNext).thenReturn('Next');
      when(() => mockL10n.onboardingStart).thenReturn('Get Started');
      when(() => mockL10n.onboardingPage1Title).thenReturn('シンプルなメモ機能');
      when(
        () => mockL10n.onboardingPage1Desc,
      ).thenReturn('思いついたアイデアやタスクを、いつでもどこでもすばやくメモに残すことができます。');
      when(() => mockL10n.onboardingPage2Title).thenReturn('どこでもつながる同期機能');
      when(
        () => mockL10n.onboardingPage2Desc,
      ).thenReturn('インターネットがないオフライン環境でもメモを書くことができ、接続時に自動でクラウドへ同期されます。');
      when(() => mockL10n.onboardingPage3Title).thenReturn('AIチャットアシスタント');
      when(
        () => mockL10n.onboardingPage3Desc,
      ).thenReturn('メモのまとめを作ったり、アイデアのブレインストーミングをAIアシスタントがサポートします。');

      mockPrefs = MockSharedPreferencesAsync();
      when(
        () => mockPrefs.getBool('onboarding_completed'),
      ).thenAnswer((_) async => false);
    });

    Widget buildOnboardingForGolden() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
        child: MaterialApp(
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
            name: 'Initial Slide',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildOnboardingForGolden(),
            ),
          ),
        ],
      ),
    );
  });
}
