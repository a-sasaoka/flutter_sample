import 'package:checks/checks.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_sample/src/features/chart/presentation/controllers/sales_chart_state.dart';
import 'package:flutter_sample/src/features/chart/presentation/widgets/animated_sales_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTitleMeta extends Mock implements TitleMeta {}

void main() {
  const sampleState7Days = SalesChartState(
    period: SalesPeriod.days7,
    spots: [
      FlSpot(0, 10000),
      FlSpot(1, 20000),
      FlSpot(2, 15000),
      FlSpot(3, 30000),
      FlSpot(4, 25000),
      FlSpot(5, 18000),
      FlSpot(6, 22000),
    ],
    dateLabels: ['9/19', '9/20', '9/21', '9/22', '9/23', '9/24', '9/25'],
    maxY: 36000,
    totalSales: 140000,
    dailyAverage: 20000,
  );

  const sampleState14Days = SalesChartState(
    period: SalesPeriod.days14,
    spots: [FlSpot(0, 500), FlSpot(1, 10000)],
    dateLabels: ['9/12', '9/13'],
    maxY: 12000,
    totalSales: 10500,
    dailyAverage: 5250,
  );

  Widget createWidgetUnderTest(SalesChartState state) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 300,
          child: AnimatedSalesChart(state: state),
        ),
      ),
    );
  }

  group('AnimatedSalesChart', () {
    testWidgets('7日間のデータでLineChartが正しく描画されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(sampleState7Days));
      await tester.pumpAndSettle();

      check(find.byType(LineChart)).findsOne();
    });

    testWidgets('14日間のデータでLineChartが正しく描画されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(sampleState14Days));
      await tester.pumpAndSettle();

      check(find.byType(LineChart)).findsOne();
    });

    testWidgets('X軸（bottomTitles）のラベルロジックの検証', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(sampleState14Days));
      await tester.pumpAndSettle();

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      final bottomTitles = lineChart.data.titlesData.bottomTitles.sideTitles;
      final mockMeta = MockTitleMeta();

      // 1. 小数の場合は非表示
      check(bottomTitles.getTitlesWidget(0.5, mockMeta)).isA<SizedBox>();

      // 2. 範囲外（負数・上限超え）の場合は非表示
      check(bottomTitles.getTitlesWidget(-1, mockMeta)).isA<SizedBox>();
      check(bottomTitles.getTitlesWidget(10, mockMeta)).isA<SizedBox>();

      // 3. 14日間の間引き（奇数インデックスは非表示）
      check(bottomTitles.getTitlesWidget(1, mockMeta)).isA<SizedBox>();

      // 4. 正常表示（偶数インデックス）
      final widget = bottomTitles.getTitlesWidget(0, mockMeta);
      check(widget).isA<SideTitleWidget>();
      check(((widget as SideTitleWidget).child as Text).data).equals('9/12');
    });

    testWidgets('Y軸（leftTitles）のラベルロジックの検証', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(sampleState14Days));
      await tester.pumpAndSettle();

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      final leftTitles = lineChart.data.titlesData.leftTitles.sideTitles;
      final mockMeta = MockTitleMeta();

      // 1. 0の時は非表示
      check(leftTitles.getTitlesWidget(0, mockMeta)).isA<SizedBox>();

      // 2. 1000未満の数値表記
      final smallValue = leftTitles.getTitlesWidget(500, mockMeta);
      check(smallValue).isA<Text>();
      check((smallValue as Text).data).equals('500');

      // 3. 1000以上のk単位表記
      final largeValue = leftTitles.getTitlesWidget(10000, mockMeta);
      check(largeValue).isA<Text>();
      check((largeValue as Text).data).equals('10k');
    });

    testWidgets('ツールチップとグリッド・ドットのコールバック検証', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(sampleState7Days));
      await tester.pumpAndSettle();

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      final data = lineChart.data;

      // グリッド線描画
      final line = data.gridData.getDrawingHorizontalLine(1000);
      check(line.strokeWidth).equals(1);

      // ドット描画
      final barData = data.lineBarsData.first;
      final dotPainter = barData.dotData.getDotPainter(
        const FlSpot(0, 10000),
        0,
        barData,
        0,
      );
      check(dotPainter).isA<FlDotCirclePainter>();

      // ツールチップ背景色
      final tooltipData = data.lineTouchData.touchTooltipData;
      final touchedSpot = LineBarSpot(barData, 0, const FlSpot(0, 10000));
      check(tooltipData.getTooltipColor(touchedSpot)).isA<Color>();

      // ツールチップアイテム生成（正常時）
      final items = tooltipData.getTooltipItems([touchedSpot]);
      check(items.length).equals(1);
      check(items.first?.text.contains('9/19')).equals(true);
      check(items.first?.text.contains('¥10,000')).equals(true);

      // ツールチップアイテム生成（範囲外インデックス）
      final outOfRangeSpot = LineBarSpot(barData, 0, const FlSpot(99, 10000));
      final outOfRangeItems = tooltipData.getTooltipItems([outOfRangeSpot]);
      check(outOfRangeItems.first?.text.startsWith('\n')).equals(true);
    });
  });
}
