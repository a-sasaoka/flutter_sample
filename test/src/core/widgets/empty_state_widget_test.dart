import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_sample/gen/assets.gen.dart';
import 'package:flutter_sample/src/core/widgets/app_lottie_widget.dart';
import 'package:flutter_sample/src/core/widgets/empty_state_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('タイトルとデフォルトのLottieアニメーションが描画されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'データがありません',
              animate: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      check(find.text('データがありません')).findsOne();
      check(find.byType(AppLottieWidget)).findsOne();
    });

    testWidgets('説明文とアクションボタンが指定されている場合に正しく描画され、タップできること', (tester) async {
      var actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'メモが0件です',
              description: '右下のボタンからメモを作成してみましょう。',
              actionLabel: 'メモを作成',
              onAction: () => actionCalled = true,
              lottie: Assets.animations.onboardingMemo,
              animate: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      check(find.text('メモが0件です')).findsOne();
      check(find.text('右下のボタンからメモを作成してみましょう。')).findsOne();
      check(find.text('メモを作成')).findsOne();

      final button = find.byType(FilledButton);
      await tester.tap(button);
      await tester.pump();

      check(actionCalled).isTrue();
    });
  });
}
