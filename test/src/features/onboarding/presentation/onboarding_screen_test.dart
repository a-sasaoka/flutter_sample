import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/widgets/widgets_test_helper.dart';

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
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
    when(
      () => mockPrefs.setBool('onboarding_completed', true),
    ).thenAnswer((_) async {});
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
      expect(find.text('シンプルなメモ機能'), findsOneWidget);
      expect(
        find.text('思いついたアイデアやタスクを、いつでもどこでもすばやくメモに残すことができます。'),
        findsOneWidget,
      );

      // スキップボタンと次へボタンがあること
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);
    });

    testWidgets('「次へ」ボタンをタップすると2枚目のスライドに切り替わること', (tester) async {
      await pumpOnboardingScreen(tester);

      // 「次へ」をタップ
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // 2ページ目の表示
      expect(find.text('どこでもつながる同期機能'), findsOneWidget);
      expect(
        find.text('インターネットがないオフライン環境でもメモを書くことができ、接続時に自動でクラウドへ同期されます。'),
        findsOneWidget,
      );
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);
    });

    testWidgets('3枚目のスライドで「はじめる」ボタンが表示され、タップすると完了処理が呼ばれること', (tester) async {
      await pumpOnboardingScreen(tester);

      // 2ページ目に切り替え
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // 3ページ目に切り替え
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // 3ページ目の表示
      expect(find.text('AIチャットアシスタント'), findsOneWidget);
      expect(
        find.text('メモのまとめを作ったり、アイデアのブレインストーミングをAIアシスタントがサポートします。'),
        findsOneWidget,
      );

      // 「はじめる」に変わっていること
      expect(find.text('Next'), findsNothing);
      expect(find.text('Get Started'), findsOneWidget);

      // 「はじめる」をタップすると、SharedPreferencesに保存されること
      await tester.tap(find.text('Get Started'));
      await tester.pump(); // Notifierの非同期処理を発火

      verify(() => mockPrefs.setBool('onboarding_completed', true)).called(1);
    });

    testWidgets('「Skip」ボタンをタップすると即座に完了処理が呼ばれること', (tester) async {
      await pumpOnboardingScreen(tester);

      // 「Skip」をタップ
      await tester.tap(find.text('Skip'));
      await tester.pump();

      verify(() => mockPrefs.setBool('onboarding_completed', true)).called(1);
    });
  });
}
