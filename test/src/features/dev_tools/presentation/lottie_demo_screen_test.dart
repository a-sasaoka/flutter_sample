import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/widgets/app_lottie_widget.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/lottie_demo_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:mocktail/mocktail.dart';

class MockLottieComposition extends Mock implements LottieComposition {}

void main() {
  group('LottieDemoScreen', () {
    Future<void> pumpScreen(
      WidgetTester tester, {
      bool animate = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: LottieDemoScreen(animate: animate),
        ),
      );
      await tester.pump();
    }

    testWidgets('初期表示で各種コントロールとアニメーションが表示されること', (tester) async {
      await pumpScreen(tester);

      check(find.text('Lottie アニメーションデモ')).findsOne();
      check(find.byType(AppLottieWidget)).findsAtLeast(1);
      check(find.byType(Slider)).findsOne();
      check(find.byType(SwitchListTile)).findsOne();
    });

    testWidgets('コントロールボタン（再生・一時停止・逆再生・停止）をタップできること', (tester) async {
      await pumpScreen(tester);

      // 初期状態は進捗0%
      check(find.text('進捗（シークバー）: 0%')).findsOne();

      // 再生ボタンをタップして進捗が進むこと
      final playButton = find.byIcon(Icons.play_arrow);
      await tester.tap(playButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      check(find.text('進捗（シークバー）: 0%')).findsNothing();

      // 一時停止ボタンをタップ
      final pauseButton = find.byIcon(Icons.pause);
      await tester.tap(pauseButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 逆再生ボタンをタップ
      final reverseButton = find.byIcon(Icons.replay);
      await tester.tap(reverseButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 停止ボタンをタップすると進捗が0%にリセットされること
      final stopButton = find.byIcon(Icons.stop);
      await tester.tap(stopButton);
      await tester.pump();
      check(find.text('進捗（シークバー）: 0%')).findsOne();
    });

    testWidgets('シークバースライダーを操作できること', (tester) async {
      await pumpScreen(tester);

      final slider = find.byType(Slider);
      check(tester.widget<Slider>(slider).value).equals(0);

      // スライダーを右にドラッグして値が更新されること
      await tester.drag(slider, const Offset(100, 0));
      await tester.pump();

      check(tester.widget<Slider>(slider).value).isGreaterThan(0);
    });

    testWidgets('ループ再生スイッチを切り替えできること', (tester) async {
      await pumpScreen(tester);

      final switchTile = find.byType(SwitchListTile);
      check(tester.widget<SwitchListTile>(switchTile).value).isTrue();

      // スイッチをタップしてOFFに切り替わること
      await tester.tap(switchTile);
      await tester.pump();

      check(tester.widget<SwitchListTile>(switchTile).value).isFalse();
    });

    testWidgets('アセット切り替えチップを選択できること', (tester) async {
      await pumpScreen(tester);

      final memoChip = find.text('オンボーディング1 (Memo)');
      await tester.dragUntilVisible(
        memoChip,
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.pump();

      // 初期状態は1つ目のチップ（Memo）が選択されていること
      final memoChoiceChip = find.widgetWithText(
        ChoiceChip,
        'オンボーディング1 (Memo)',
      );
      check(tester.widget<ChoiceChip>(memoChoiceChip).selected).isTrue();

      // 2つ目のチップ（Sync）をタップ
      final syncChip = find.text('オンボーディング2 (Sync)');
      await tester.tap(syncChip);
      await tester.pump();

      // 2つ目のチップが選択状態になること
      final syncChoiceChip = find.widgetWithText(
        ChoiceChip,
        'オンボーディング2 (Sync)',
      );
      check(tester.widget<ChoiceChip>(syncChoiceChip).selected).isTrue();
    });

    testWidgets('animate: true で初期化した場合に正常に再生が開始されること', (tester) async {
      await pumpScreen(tester, animate: true);

      check(find.byType(LottieDemoScreen)).findsOne();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      check(find.text('進捗（シークバー）: 0%')).findsNothing();
    });

    testWidgets('単発再生時に完了するとスナックバーが表示されること', (tester) async {
      await pumpScreen(tester);

      // ループスイッチをOFFにする
      final switchTile = find.byType(SwitchListTile);
      await tester.ensureVisible(switchTile);
      await tester.pumpAndSettle();
      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      // 再生ボタンを押して完了まで進める
      final playButton = find.byIcon(Icons.play_arrow);
      await tester.ensureVisible(playButton);
      await tester.pumpAndSettle();
      await tester.tap(playButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2, milliseconds: 50));
      await tester.pump();

      check(find.text('アニメーションが完了しました！')).findsOne();

      // スナックバーが自動消去されるのを待つ
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 停止状態でループスイッチを再度ONにした場合、自動的に再生が再開されること
      await tester.ensureVisible(switchTile);
      await tester.pumpAndSettle();
      await tester.tap(switchTile);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('ループ再生時に完了ステータスを受け取ると先頭から再生されること', (tester) async {
      await pumpScreen(tester);

      // AppLottieWidgetのonLoadedコールバックをテスト
      final lottieFinder = find.byType(AppLottieWidget);
      check(lottieFinder).findsAtLeast(1);

      final lottieWidget = tester.widget<AppLottieWidget>(lottieFinder.first);
      final mockComposition = MockLottieComposition();
      when(
        () => mockComposition.duration,
      ).thenReturn(const Duration(seconds: 2));
      lottieWidget.onLoaded?.call(mockComposition);
      await tester.pump();

      // 再生ボタンを押して時間を進める（ループ再生なのでスナックバーは出ず、先頭から再開されること）
      final playButton = find.byIcon(Icons.play_arrow);
      await tester.tap(playButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 100));

      check(find.byType(SnackBar)).findsNothing();
    });
  });
}
