import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/chart/presentation/controllers/sales_chart_controller.dart';
import 'package:flutter_sample/src/features/chart/presentation/controllers/sales_chart_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('SalesChartController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態は7日間の売上データが正しく構築されていること', () {
      // AutoDisposeなProviderを保持するためActの前にlistenする
      container.listen(salesChartControllerProvider, (_, _) {});

      final state = container.read(salesChartControllerProvider);

      // 期間の検証
      check(state.period).equals(SalesPeriod.days7);

      // データ件数（7件）
      check(state.spots.length).equals(7);
      check(state.dateLabels.length).equals(7);
      check(state.dateLabels.first).equals('9/19');
      check(state.dateLabels.last).equals('9/25');

      // 合計売上・日別平均・Y軸最大値の検証
      check(state.totalSales).equals(151900);
      check(state.dailyAverage).equals(21700);
      check(state.maxY).equals(33600); // 28000 * 1.2
    });

    test('14日間に切り替えたとき、14日分のデータが正しく構築されること', () {
      container.listen(salesChartControllerProvider, (_, _) {});

      container
          .read(salesChartControllerProvider.notifier)
          .switchPeriod(SalesPeriod.days14);

      final state = container.read(salesChartControllerProvider);

      check(state.period).equals(SalesPeriod.days14);
      check(state.spots.length).equals(14);
      check(state.dateLabels.length).equals(14);
      check(state.dateLabels.first).equals('9/12');
      check(state.dateLabels.last).equals('9/25');

      check(state.totalSales).equals(265300);
      check(state.dailyAverage).equals(18950);
      check(state.maxY).equals(33600);
    });

    test('14日間から7日間に戻したとき、正しく7日分のデータに切り替わること', () {
      container.listen(salesChartControllerProvider, (_, _) {});

      container
          .read(salesChartControllerProvider.notifier)
          .switchPeriod(SalesPeriod.days14);
      check(
        container.read(salesChartControllerProvider).period,
      ).equals(SalesPeriod.days14);

      container
          .read(salesChartControllerProvider.notifier)
          .switchPeriod(SalesPeriod.days7);
      final state = container.read(salesChartControllerProvider);

      check(state.period).equals(SalesPeriod.days7);
      check(state.spots.length).equals(7);
    });
  });
}
