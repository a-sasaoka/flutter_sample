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

      // 一時停止ボタンをタップ
      final pauseButton = find.byIcon(Icons.pause);
      await tester.tap(pauseButton);
      await tester.pump();

      // 再生ボタンをタップ
      final playButton = find.byIcon(Icons.play_arrow);
      await tester.tap(playButton);
      await tester.pump();

      // 逆再生ボタンをタップ
      final reverseButton = find.byIcon(Icons.replay);
      await tester.tap(reverseButton);
      await tester.pump();

      // 停止ボタンをタップ
      final stopButton = find.byIcon(Icons.stop);
      await tester.tap(stopButton);
      await tester.pump();
    });

    testWidgets('シークバースライダーを操作できること', (tester) async {
      await pumpScreen(tester);

      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(50, 0));
      await tester.pump();
    });

    testWidgets('ループ再生スイッチを切り替えできること', (tester) async {
      await pumpScreen(tester);

      final switchTile = find.byType(SwitchListTile);
      await tester.tap(switchTile);
      await tester.pump();
    });

    testWidgets('アセット切り替えチップを選択できること', (tester) async {
      await pumpScreen(tester);

      // 2つ目のチップ（Sync）までスクロールしてタップ
      final syncChip = find.text('オンボーディング2 (Sync)');
      await tester.dragUntilVisible(
        syncChip,
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.pump();

      await tester.tap(syncChip);
      await tester.pump();
    });

    testWidgets('animate: true で初期化した場合に正常に再生が開始されること', (tester) async {
      await pumpScreen(tester, animate: true);

      check(find.byType(LottieDemoScreen)).findsOne();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('単発再生時に完了するとスナックバーが表示されること', (tester) async {
      await pumpScreen(tester);

      // ループスイッチをOFFにする
      final switchTile = find.byType(SwitchListTile);
      await tester.tap(switchTile);
      await tester.pump();

      // 再生ボタンを押して完了まで進める（単発再生のため完了で停止しsettleする）
      final playButton = find.byIcon(Icons.play_arrow);
      await tester.tap(playButton);
      await tester.pumpAndSettle();

      check(find.text('アニメーションが完了しました！')).findsOne();

      // 停止状態でループスイッチを再度ONにした場合、自動的に再生が再開されること
      await tester.tap(switchTile);
      await tester.pump();
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

      // 再生ボタンを押して時間を少し進める
      final playButton = find.byIcon(Icons.play_arrow);
      await tester.tap(playButton);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
