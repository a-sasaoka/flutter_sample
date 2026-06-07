import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/chart/application/chart_notifier.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_type.dart';
import 'package:flutter_sample/src/features/chart/presentation/chart_display_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../golden_test_helper.dart';

void main() {
  group('ChartDisplayScreen Golden Tests', () {
    // グラフ画面をテスト用に構築する関数
    Widget buildChartDisplayForGolden({
      required ThemeMode themeMode,
      required ChartType chartType,
      bool isEmpty = false,
    }) {
      final container = ProviderContainer();

      // グラフの種類を設定します
      container.read(chartProvider.notifier).updateChartType(chartType);

      // データが空の状態をテストする場合はリセットします
      if (isEmpty) {
        container.read(chartProvider.notifier).reset();
      }

      return UncontrolledProviderScope(
        container: container,
        child: buildGoldenTestApp(
          home: const ChartDisplayScreen(),
          themeMode: themeMode,
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'ChartDisplayScreen の描画 (折れ線/棒/円グラフ/空データ)',
      fileName: 'chart_display_screen',
      pumpBeforeTest: (tester) async => tester.pumpAndSettle(),
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Line Chart - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildChartDisplayForGolden(
                themeMode: ThemeMode.light,
                chartType: ChartType.line,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Bar Chart - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildChartDisplayForGolden(
                themeMode: ThemeMode.dark,
                chartType: ChartType.bar,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Pie Chart - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildChartDisplayForGolden(
                themeMode: ThemeMode.light,
                chartType: ChartType.pie,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Empty State - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildChartDisplayForGolden(
                themeMode: ThemeMode.light,
                chartType: ChartType.line,
                isEmpty: true,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
