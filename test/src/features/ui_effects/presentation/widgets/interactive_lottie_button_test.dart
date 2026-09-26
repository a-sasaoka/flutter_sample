import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_sample/gen/assets.gen.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/ui_effects/presentation/controllers/submit_animation_controller.dart';
import 'package:flutter_sample/src/features/ui_effects/presentation/widgets/interactive_lottie_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Widget _buildTestApp({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('InteractiveLottieButton Widget Tests', () {
    testWidgets('初期状態でデフォルトのテキストとアイコンが表示されること', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: InteractiveLottieButton(
            assetPath: Assets.animations.successCheck.path,
            onComplete: () {},
            animate: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      check(find.text('データを送信する')).findsOne();
      check(find.byIcon(Icons.send_rounded)).findsOne();
    });

    testWidgets('カスタムbuttonTextが指定された場合、それが表示されること', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: InteractiveLottieButton(
            assetPath: Assets.animations.successCheck.path,
            onComplete: () {},
            buttonText: '今すぐ登録',
            animate: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      check(find.text('今すぐ登録')).findsOne();
    });

    testWidgets('タップするとローディング状態になり、ボタンが無効化されること', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: InteractiveLottieButton(
            assetPath: Assets.animations.successCheck.path,
            onComplete: () {},
            animate: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ボタンをタップ
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // ローディング状態（Lottieコンテンツが表示される）
      check(find.byKey(const ValueKey('lottie_content'))).findsOne();

      // ローディング中はボタンが無効（onPressedがnull）であること
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      check(button.onPressed).isNull();

      // 内部で動いている非同期タイマーを消化して完了させる
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('成功時にonCompleteコールバックが発火すること', (tester) async {
      var completed = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: Consumer(
            builder: (context, ref, child) {
              return InteractiveLottieButton(
                assetPath: Assets.animations.successCheck.path,
                onComplete: () {
                  completed = true;
                },
                animate: false,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ボタンをタップして完了まで進める
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      check(completed).isTrue();
    });

    testWidgets('エラー状態のときに再試行テキストとアイコンが表示されること', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ja'),
            home: Scaffold(
              body: Center(
                child: InteractiveLottieButton(
                  assetPath: Assets.animations.successCheck.path,
                  onComplete: () {},
                  animate: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 手動でエラー状態にする（FakeAsync空間のため await せずに pump で時間を進める）
      unawaited(
        container
            .read(submitAnimationControllerProvider.notifier)
            .submit(duration: Duration.zero, isSuccess: false),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      check(find.text('再試行する')).findsOne();
      check(find.byIcon(Icons.refresh_rounded)).findsOne();

      // エラー状態でもボタンは有効（onPressed != null）であること
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      check(button.onPressed).isNotNull();

      // 再試行ボタンをタップすると再度ローディングになること
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      check(find.byKey(const ValueKey('lottie_content'))).findsOne();

      // タイマーを消化して完了させる
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('animate: true の場合、成功アニメーションが完了してonCompleteが呼ばれること', (
      tester,
    ) async {
      var completed = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: InteractiveLottieButton(
            assetPath: Assets.animations.successCheck.path,
            onComplete: () {
              completed = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      // アニメーション完了まで時間を進める
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      check(completed).isTrue();
    });

    testWidgets('idle状態にリセットされた場合、アニメーションコントローラーがリセットされること', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ja'),
            home: Scaffold(
              body: Center(
                child: InteractiveLottieButton(
                  assetPath: Assets.animations.successCheck.path,
                  onComplete: () {},
                  animate: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 一度エラー状態へ遷移させてからリセットを呼び出し、idleへの状態変化を検知させる
      unawaited(
        container
            .read(submitAnimationControllerProvider.notifier)
            .submit(duration: Duration.zero, isSuccess: false),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      container.read(submitAnimationControllerProvider.notifier).reset();
      await tester.pumpAndSettle();

      check(find.text('データを送信する')).findsOne();
    });

    testWidgets('複数のボタンが存在する場合、タップした送信元ボタンのみonCompleteが呼ばれること', (tester) async {
      var completedA = false;
      var completedB = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: Column(
            children: [
              InteractiveLottieButton(
                assetPath: Assets.animations.successCheck.path,
                buttonText: 'ボタンA',
                onComplete: () => completedA = true,
                animate: false,
              ),
              InteractiveLottieButton(
                assetPath: Assets.animations.successCheck.path,
                buttonText: 'ボタンB',
                onComplete: () => completedB = true,
                animate: false,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ボタンAのみをタップ
      await tester.tap(find.text('ボタンA'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // ボタンAのコールバックのみ発火し、ボタンBは発火しないこと
      check(completedA).isTrue();
      check(completedB).isFalse();
    });
  });
}
