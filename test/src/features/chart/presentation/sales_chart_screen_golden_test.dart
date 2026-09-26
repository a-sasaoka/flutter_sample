import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/chart/presentation/controllers/sales_chart_controller.dart';
import 'package:flutter_sample/src/features/chart/presentation/controllers/sales_chart_state.dart';
import 'package:flutter_sample/src/features/chart/presentation/sales_chart_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../golden_test_helper.dart';

void main() {
  group('SalesChartScreen Golden Tests', () {
    Widget buildSalesChartForGolden({
      required ThemeMode themeMode,
      required SalesPeriod period,
    }) {
      final container = ProviderContainer();

      if (period == SalesPeriod.days14) {
        container
            .read(salesChartControllerProvider.notifier)
            .switchPeriod(SalesPeriod.days14);
      }

      return UncontrolledProviderScope(
        container: container,
        child: buildGoldenTestApp(
          home: const SalesChartScreen(),
          themeMode: themeMode,
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'SalesChartScreen の描画 (7日間/14日間/Light/Dark)',
      fileName: 'sales_chart_screen',
      pumpBeforeTest: (tester) async => await tester.pumpAndSettle(),
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: '7 Days - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildSalesChartForGolden(
                themeMode: ThemeMode.light,
                period: SalesPeriod.days7,
              ),
            ),
          ),
          GoldenTestScenario(
            name: '14 Days - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildSalesChartForGolden(
                themeMode: ThemeMode.dark,
                period: SalesPeriod.days14,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
