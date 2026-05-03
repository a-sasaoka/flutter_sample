import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/chart/application/chart_notifier.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_type.dart';
import 'package:flutter_sample/src/features/chart/presentation/chart_display_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockTitleMeta extends Mock implements TitleMeta {}

void main() {
  Widget createWidgetUnderTest(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ja'),
        home: ChartDisplayScreen(),
      ),
    );
  }

  group('ChartDisplayScreen', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('初期表示で折れ線グラフが正しく表示されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Item1'), findsWidgets);
      expect(find.text('10.0'), findsWidgets);
    });

    testWidgets('棒グラフが正しく表示されること', (tester) async {
      container.read(chartProvider.notifier).updateChartType(ChartType.bar);

      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('Item2'), findsWidgets);
      expect(find.text('20.0'), findsWidgets);
    });

    testWidgets('円グラフが正しく表示され、カラーのループが動作すること', (tester) async {
      container.read(chartProvider.notifier).updateChartType(ChartType.pie);
      // カラー数(6)を超える項目を追加してループを発生させる
      for (var i = 0; i < 5; i++) {
        container.read(chartProvider.notifier).addItem();
      }

      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);
      final pieChart = tester.widget<PieChart>(find.byType(PieChart));
      // 0番目と6番目の色が同じであることを確認 (moduloの検証)
      expect(
        pieChart.data.sections[0].color,
        pieChart.data.sections[6].color,
      );
    });

    testWidgets('データが空の場合にメッセージが表示されること', (tester) async {
      // 項目をすべて削除
      final items = container.read(chartProvider).items;
      for (final item in items) {
        container.read(chartProvider.notifier).removeItem(item.id);
      }

      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      expect(find.text('データがありません。まず項目を追加してください。'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('LineChartのX軸タイトル: 整数以外、間引き、範囲外の検証', (tester) async {
      container.read(chartProvider.notifier).updateChartType(ChartType.line);
      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      final titlesData = lineChart.data.titlesData.bottomTitles.sideTitles;
      final mockMeta = MockTitleMeta();

      // 1. 整数以外は SizedBox.shrink
      expect(titlesData.getTitlesWidget(0.5, mockMeta), isA<SizedBox>());

      // 2. 正常なインデックス
      final valid = titlesData.getTitlesWidget(0, mockMeta);
      expect(valid, isA<SideTitleWidget>());
      expect(((valid as SideTitleWidget).child as Text).data, 'Item1');

      // 3. 範囲外
      expect(titlesData.getTitlesWidget(-1, mockMeta), isA<SizedBox>());
      expect(titlesData.getTitlesWidget(100, mockMeta), isA<SizedBox>());

      // 4. 間引きの検証 (項目を11個にして interval=2 にする)
      for (var i = 0; i < 9; i++) {
        container.read(chartProvider.notifier).addItem();
      }
      await tester.pumpAndSettle();

      final lineChart2 = tester.widget<LineChart>(find.byType(LineChart));
      final titlesData2 = lineChart2.data.titlesData.bottomTitles.sideTitles;

      // index 1 は間引かれる (1 % 2 != 0)
      expect(titlesData2.getTitlesWidget(1, mockMeta), isA<SizedBox>());
    });

    testWidgets('BarChartのX軸タイトル: 整数以外、間引き、範囲外の検証', (tester) async {
      container.read(chartProvider.notifier).updateChartType(ChartType.bar);
      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final titlesData = barChart.data.titlesData.bottomTitles.sideTitles;
      final mockMeta = MockTitleMeta();

      // 1. 整数以外
      expect(titlesData.getTitlesWidget(0.1, mockMeta), isA<SizedBox>());

      // 2. 正常
      final valid = titlesData.getTitlesWidget(0, mockMeta);
      expect(valid, isA<SideTitleWidget>());

      // 3. 範囲外
      expect(titlesData.getTitlesWidget(99, mockMeta), isA<SizedBox>());

      // 4. 間引き (21個にして interval=5 にする)
      for (var i = 0; i < 19; i++) {
        container.read(chartProvider.notifier).addItem();
      }
      await tester.pumpAndSettle();

      final barChart2 = tester.widget<BarChart>(find.byType(BarChart));
      final titlesData2 = barChart2.data.titlesData.bottomTitles.sideTitles;

      // index 1 は間引かれる (1 % 5 != 0)
      expect(titlesData2.getTitlesWidget(1, mockMeta), isA<SizedBox>());
    });

    testWidgets('左軸(Y軸)のラベルが正しくレンダリングされること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      final leftTitles = lineChart.data.titlesData.leftTitles.sideTitles;

      final widget = leftTitles.getTitlesWidget(10, MockTitleMeta());
      expect(widget, isA<Text>());
      expect((widget as Text).data, '10');
    });
  });
}
