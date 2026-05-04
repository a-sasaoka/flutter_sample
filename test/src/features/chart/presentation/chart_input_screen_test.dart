import 'package:flutter/material.dart';
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
    late String? attemptedPath;
    late GoRouter router;

    setUp(() {
      container = ProviderContainer();
      attemptedPath = null;
      router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const ChartInputScreen(),
          ),
        ],
        errorBuilder: (context, state) {
          attemptedPath = state.uri.toString();
          return const Scaffold(body: Text('Dummy Error Screen'));
        },
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('初期表示が正しくされること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      expect(find.byType(ChartInputScreen), findsOneWidget);
      expect(find.byType(SegmentedButton<ChartType>), findsOneWidget);
      expect(find.text('Item1'), findsOneWidget); // Default item 1 label
      expect(find.text('10.0'), findsOneWidget); // Default item 1 value
      expect(find.text('Item2'), findsOneWidget); // Default item 2 label
      expect(find.text('20.0'), findsOneWidget); // Default item 2 value
    });

    testWidgets('グラフ種類を変更できること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      final stateBefore = container.read(chartProvider);
      expect(stateBefore.chartType, ChartType.line);

      // 棒グラフを選択
      await tester.tap(find.text('棒グラフ'));
      await tester.pumpAndSettle();

      final stateAfter = container.read(chartProvider);
      expect(stateAfter.chartType, ChartType.bar);
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
      expect(state.items[0].label, 'UpdatedLabel');
    });

    testWidgets('数値を更新できること（正常な数値）', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(1), '50.5');
      await tester.pumpAndSettle();

      final state = container.read(chartProvider);
      expect(state.items[0].value, 50.5);
    });

    testWidgets('数値を更新できること（不正な数値の場合は0.0になること）', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(1), 'invalid');
      await tester.pumpAndSettle();

      final state = container.read(chartProvider);
      expect(state.items[0].value, 0.0);
    });

    testWidgets('項目を追加できること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      final addBtn = find.widgetWithIcon(FloatingActionButton, Icons.add);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      final state = container.read(chartProvider);
      expect(state.items.length, 3);
      expect(state.items[2].label, 'Item3');
    });

    testWidgets('項目を削除できること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      final deleteBtns = find.byIcon(Icons.delete);
      expect(deleteBtns, findsNWidgets(2));

      await tester.tap(deleteBtns.first);
      await tester.pumpAndSettle();

      final state = container.read(chartProvider);
      expect(state.items.length, 1);
      expect(state.items[0].label, 'Item2');
    });

    testWidgets('グラフ表示画面への遷移ボタンが動作すること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      final viewBtn = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(IconButton),
      );

      await tester.tap(viewBtn);
      await tester.pumpAndSettle();

      expect(attemptedPath, '/chart-input/display');
    });

    testWidgets('画面外タップでキーボードが閉じること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container, router));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.tap(textFields.first);
      await tester.pumpAndSettle();

      // Focusが当たっていることを確認
      final BuildContext context = tester.element(textFields.first);
      expect(FocusScope.of(context).hasFocus, isTrue);

      // AppBarなど画面外をタップ
      await tester.tap(find.byType(AppBar));
      await tester.pumpAndSettle();

      // Focusが外れていることを確認
      expect(FocusScope.of(context).hasFocus, isFalse);
    });
  });
}
