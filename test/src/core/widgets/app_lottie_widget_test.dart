import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_sample/gen/assets.gen.dart';
import 'package:flutter_sample/src/core/widgets/app_lottie_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  group('AppLottieWidget', () {
    testWidgets('AppLottieWidget.asset で Lottie アニメーションが正しく描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLottieWidget.asset(
              lottie: Assets.animations.emptyBox,
              width: 150,
              height: 150,
              animate: false,
            ),
          ),
        ),
      );
      await tester.pump();

      check(find.byType(AppLottieWidget)).findsOne();
      check(find.byType(LottieBuilder)).findsOne();
    });

    testWidgets('AppLottieWidget.network でネットワーク Lottie が正しく描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLottieWidget.network(
              url: 'https://example.com/test.json',
              width: 120,
              height: 120,
              animate: false,
            ),
          ),
        ),
      );
      await tester.pump();

      check(find.byType(AppLottieWidget)).findsOne();
      check(find.byType(LottieBuilder)).findsOne();
    });

    testWidgets('コントローラーと各種オプションを渡して正しく動作すること', (tester) async {
      late AnimationController testController;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                testController = AnimationController(
                  vsync: const TestVSync(),
                  duration: const Duration(seconds: 1),
                );
                return AppLottieWidget.asset(
                  lottie: Assets.animations.successCheck,
                  controller: testController,
                  repeat: false,
                  reverse: true,
                  fit: BoxFit.cover,
                  animate: false,
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      check(find.byType(AppLottieWidget)).findsOne();
      check(find.byType(LottieBuilder)).findsOne();
      testController.dispose();
    });

    testWidgets('エラー時または不正なリソースの時にフォールバックアイコンが表示されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // errorBuilder を直接検証 (network)
                const networkWidget = AppLottieWidget.network(
                  url: 'invalid_url',
                  animate: false,
                );
                final networkBuilt =
                    networkWidget.build(context) as LottieBuilder;
                return networkBuilt.errorBuilder!(
                  context,
                  Exception('load error'),
                  StackTrace.empty,
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      check(find.byIcon(Icons.animation)).findsOne();
    });

    testWidgets(
      'AppLottieWidget.asset の errorBuilder が呼ばれた場合にフォールバックアイコンが表示されること',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  // errorBuilder を直接検証 (asset)
                  final assetWidget = AppLottieWidget.asset(
                    lottie: Assets.animations.emptyBox,
                    animate: false,
                  );
                  final assetBuilt =
                      assetWidget.build(context) as LottieBuilder;
                  return assetBuilt.errorBuilder!(
                    context,
                    Exception('asset load error'),
                    StackTrace.empty,
                  );
                },
              ),
            ),
          ),
        );
        await tester.pump();

        check(find.byIcon(Icons.animation)).findsOne();
      },
    );
  });
}
