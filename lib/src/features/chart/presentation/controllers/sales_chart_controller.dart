import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_sample/src/features/chart/presentation/controllers/sales_chart_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sales_chart_controller.g.dart';

/// 🛒 売上推移グラフの状態管理コントローラー
@riverpod
class SalesChartController extends _$SalesChartController {
  /// 14日分のサンプル売上データ（Dart 3 Records）
  static const List<({String date, int amount})> _sampleDailySales = [
    (date: '9/12', amount: 12500),
    (date: '9/13', amount: 14800),
    (date: '9/14', amount: 10200),
    (date: '9/15', amount: 18900),
    (date: '9/16', amount: 16500),
    (date: '9/17', amount: 21000),
    (date: '9/18', amount: 19500),
    (date: '9/19', amount: 17200),
    (date: '9/20', amount: 15400),
    (date: '9/21', amount: 23000),
    (date: '9/22', amount: 20500),
    (date: '9/23', amount: 25000),
    (date: '9/24', amount: 22800),
    (date: '9/25', amount: 28000),
  ];

  @override
  SalesChartState build() {
    // 初期状態は「7日間」を表示
    return _calculateState(SalesPeriod.days7);
  }

  /// 表示期間を切り替える
  void switchPeriod(SalesPeriod period) {
    state = _calculateState(period);
  }

  /// 選択された期間に応じたグラフ状態を生成
  SalesChartState _calculateState(SalesPeriod period) {
    final count = period == SalesPeriod.days7 ? 7 : 14;
    final targetData = _sampleDailySales.sublist(
      _sampleDailySales.length - count,
    );

    // グラフの座標（X: 0からのインデックス, Y: 売上金額）
    final spots = [
      for (final (index, item) in targetData.indexed)
        FlSpot(index.toDouble(), item.amount.toDouble()),
    ];

    // 日付ラベル
    final dateLabels = targetData.map((e) => e.date).toList();

    // 合計売上・日別平均
    final totalSales = targetData.fold<int>(
      0,
      (sum, item) => sum + item.amount,
    );
    final dailyAverage = totalSales ~/ targetData.length;

    // Y軸の最大値（最大金額に約20%の余白を加えて見切れを防止）
    final maxAmount = targetData
        .map((e) => e.amount)
        .reduce((a, b) => a > b ? a : b);
    final maxY = (maxAmount * 1.2).ceilToDouble();

    return SalesChartState(
      period: period,
      spots: spots,
      dateLabels: dateLabels,
      maxY: maxY,
      totalSales: totalSales,
      dailyAverage: dailyAverage,
    );
  }
}
