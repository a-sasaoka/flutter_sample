import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../core/widgets/widgets_test_helper.dart';
import '../onboarding_test_helper.dart';

void main() {
  late MockAppLocalizations mockL10n;
  late MockSharedPreferencesAsync mockPrefs;

  setUp(() {
    mockL10n = setupMockL10n();
    mockPrefs = setupMockPrefs();
  });

  Future<void> pumpOnboardingScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ja')],
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('OnboardingScreen ウィジェットテスト', () {
    testWidgets('初期表示で1枚目のスライドが正しく表示されること', (tester) async {
      await pumpOnboardingScreen(tester);

      // 1ページ目のタイトルと説明文が表示されていること
      check(find.text(mockL10n.onboardingPage1Title)).findsOne();
      check(find.text(mockL10n.onboardingPage1Desc)).findsOne();

      // スキップボタンと次へボタンがあること
      check(find.text(mockL10n.onboardingSkip)).findsOne();
      check(find.text(mockL10n.onboardingNext)).findsOne();
      check(find.text(mockL10n.onboardingStart)).findsNothing();
    });

    testWidgets('「次へ」ボタンをタップすると2枚目のスライドに切り替わること', (tester) async {
      await pumpOnboardingScreen(tester);

      // 「次へ」をタップ
      await tester.tap(find.text(mockL10n.onboardingNext));
      await tester.pumpAndSettle();

      // 2ページ目の表示
      check(find.text(mockL10n.onboardingPage2Title)).findsOne();
      check(find.text(mockL10n.onboardingPage2Desc)).findsOne();
      check(find.text(mockL10n.onboardingNext)).findsOne();
      check(find.text(mockL10n.onboardingStart)).findsNothing();
    });

    testWidgets('3枚目のスライドで「はじめる」ボタンが表示され、タップすると完了処理が呼ばれること', (tester) async {
      await pumpOnboardingScreen(tester);

      // 2ページ目に切り替え
      await tester.tap(find.text(mockL10n.onboardingNext));
      await tester.pumpAndSettle();

      // 3ページ目に切り替え
      await tester.tap(find.text(mockL10n.onboardingNext));
      await tester.pumpAndSettle();

      // 3ページ目の表示
      check(find.text(mockL10n.onboardingPage3Title)).findsOne();
      check(find.text(mockL10n.onboardingPage3Desc)).findsOne();

      // 「はじめる」に変わっていること
      check(find.text(mockL10n.onboardingNext)).findsNothing();
      check(find.text(mockL10n.onboardingStart)).findsOne();

      // 「はじめる」をタップすると、SharedPreferencesに保存されること
      await tester.tap(find.text(mockL10n.onboardingStart));
      await tester.pump(); // Notifierの非同期処理を発火

      verify(() => mockPrefs.setBool('onboarding_completed', true)).called(1);
    });

    testWidgets('「Skip」ボタンをタップすると即座に完了処理が呼ばれること', (tester) async {
      await pumpOnboardingScreen(tester);

      // 「Skip」をタップ
      await tester.tap(find.text(mockL10n.onboardingSkip));
      await tester.pump();

      verify(() => mockPrefs.setBool('onboarding_completed', true)).called(1);
    });
  });
}
