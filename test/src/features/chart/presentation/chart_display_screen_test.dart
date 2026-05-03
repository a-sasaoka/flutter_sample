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

    testWidgets('折れ線グラフが正しく表示されること', (tester) async {
      container.read(chartProvider.notifier).updateChartType(ChartType.line);

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

    testWidgets('円グラフが正しく表示されること', (tester) async {
      container.read(chartProvider.notifier).updateChartType(ChartType.pie);

      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);
      expect(find.text('Item1'), findsWidgets);
      expect(find.text('10.0'), findsWidgets);
    });

    testWidgets('LineChartのX軸のタイトルが正しくレンダリングされること（範囲内および範囲外）', (tester) async {
      container.read(chartProvider.notifier).updateChartType(ChartType.line);
      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      final titlesData = lineChart.data.titlesData.bottomTitles.sideTitles;

      final mockMeta = MockTitleMeta();

      // 正常なインデックス
      final validWidget = titlesData.getTitlesWidget(0, mockMeta);
      expect(validWidget, isA<SideTitleWidget>());
      final textWidget = (validWidget as SideTitleWidget).child as Text;
      expect(textWidget.data, 'Item1');

      // 範囲外のインデックス（マイナス）
      final invalidWidget1 = titlesData.getTitlesWidget(-1, mockMeta);
      expect(invalidWidget1, isA<SizedBox>());

      // 範囲外のインデックス（要素数以上）
      final invalidWidget2 = titlesData.getTitlesWidget(99, mockMeta);
      expect(invalidWidget2, isA<SizedBox>());
    });

    testWidgets('BarChartのX軸のタイトルが正しくレンダリングされること（範囲内および範囲外）', (tester) async {
      container.read(chartProvider.notifier).updateChartType(ChartType.bar);
      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final titlesData = barChart.data.titlesData.bottomTitles.sideTitles;

      final mockMeta = MockTitleMeta();

      // 正常なインデックス
      final validWidget = titlesData.getTitlesWidget(0, mockMeta);
      expect(validWidget, isA<SideTitleWidget>());
      final textWidget = (validWidget as SideTitleWidget).child as Text;
      expect(textWidget.data, 'Item1');

      // 範囲外のインデックス（マイナス）
      final invalidWidget1 = titlesData.getTitlesWidget(-1, mockMeta);
      expect(invalidWidget1, isA<SizedBox>());

      // 範囲外のインデックス（要素数以上）
      final invalidWidget2 = titlesData.getTitlesWidget(99, mockMeta);
      expect(invalidWidget2, isA<SizedBox>());
    });
  });
}
