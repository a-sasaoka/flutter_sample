import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/chart/application/chart_notifier.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_type.dart';
import 'package:flutter_sample/src/features/chart/presentation/chart_input_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Widget createWidgetUnderTest(ProviderContainer container, GoRouter router) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
      ),
    );
  }

  group('ChartInputScreen', () {
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      container = ProviderContainer();
      router = GoRouter(
        initialLocation: '/chart-input',
        routes: [
          GoRoute(
            path: '/chart-input',
            builder: (context, state) => const ChartInputScreen(),
            routes: [
              GoRoute(
                path: 'display',
                builder: (context, state) =>
                    const Scaffold(body: Text('Display')),
              ),
            ],
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('初期表示が正しくされること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      check(find.byType(ChartInputScreen)).findsOne();
      check(find.byType(SegmentedButton<ChartType>)).findsOne();
      check(find.text('Item1')).findsOne(); // Default item 1 label
      check(find.text('10.0')).findsOne(); // Default item 1 value
      check(find.text('Item2')).findsOne(); // Default item 2 label
      check(find.text('20.0')).findsOne(); // Default item 2 value

      // 新しいデザインの確認
      check(find.byType(Card)).findsAtLeast(2);
      check(find.byIcon(Icons.label_outline)).findsAtLeast(2);
    });

    testWidgets('グラフ種類を変更できること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      final stateBefore = container.read(chartProvider);
      check(stateBefore.chartType).equals(ChartType.line);

      // 棒グラフを選択
      await tester.tap(find.text('棒グラフ'));
      await tester.pumpAndSettle();

      final stateAfter = container.read(chartProvider);
      check(stateAfter.chartType).equals(ChartType.bar);
    });

    testWidgets('ラベルを更新できること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      // index 0: Item1 label, index 1: Item1 value,
      // index 2: Item2 label, index 3: Item2 value
      await tester.enterText(textFields.at(0), 'UpdatedLabel');
      await tester.pumpAndSettle();

      final state = container.read(chartProvider);
      check(state.items[0].label).equals('UpdatedLabel');
    });

    testWidgets('数値を更新できること（正常な数値）', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(1), '50.5');
      await tester.pumpAndSettle();

      final state = container.read(chartProvider);
      check(state.items[0].value).equals(50.5);
    });

    testWidgets('項目を追加できること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      final addBtn = find.byType(FloatingActionButton);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      final state = container.read(chartProvider);
      check(state.items.length).equals(3);
      check(state.items[2].label).equals('Item3');
    });

    testWidgets('項目を削除できること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      final deleteBtns = find.byIcon(Icons.remove_circle_outline);
      check(deleteBtns).findsExactly(2);

      await tester.tap(deleteBtns.first);
      await tester.pumpAndSettle();

      final state = container.read(chartProvider);
      check(state.items.length).equals(1);
      check(state.items[0].label).equals('Item2');
    });

    testWidgets('全削除ボタンが動作すること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      // 初期状態で2つあることを確認
      check(container.read(chartProvider).items.length).equals(2);

      // 1. キャンセルする場合
      await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
      await tester.pumpAndSettle();
      check(find.byType(AlertDialog)).findsOne();

      await tester.tap(find.widgetWithText(TextButton, '閉じる'));
      await tester.pumpAndSettle();

      check(find.byType(AlertDialog)).findsNothing();
      check(container.read(chartProvider).items.length).equals(2); // 削除されていないこと

      // 2. 実行する場合
      await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
      await tester.pumpAndSettle();

      // 実行
      await tester.tap(find.widgetWithText(TextButton, 'すべて削除'));
      await tester.pumpAndSettle();

      // 項目が空になっていること
      check(container.read(chartProvider).items).isEmpty();
      check(find.text('データがありません。まず項目を追加してください。')).findsOne();
    });

    testWidgets('グラフ表示画面への遷移ボタンが動作すること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      final viewBtn = find.byIcon(Icons.bar_chart).last;

      await tester.tap(viewBtn);
      await tester.pumpAndSettle();

      check(find.text('Display')).findsOne();
    });

    testWidgets('画面外タップでキーボードが閉じること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.tap(textFields.first);
      await tester.pumpAndSettle();

      // Focusが当たっていることを確認
      final BuildContext context = tester.element(textFields.first);
      check(FocusScope.of(context).focusedChild).isNotNull();

      // AppBarなど画面外をタップ
      await tester.tap(find.byType(AppBar));
      await tester.pumpAndSettle();

      // Focusが外れていることを確認
      check(FocusScope.of(context).focusedChild).isNull();
    });
  });
}
