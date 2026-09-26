import 'package:fl_chart/fl_chart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sales_chart_state.freezed.dart';

/// 📊 グラフの表示期間
enum SalesPeriod {
  /// 7日間
  days7,

  /// 14日間
  days14,
}

/// 📈 売上推移グラフの状態モデル
@freezed
sealed class SalesChartState with _$SalesChartState {
  /// コンストラクタ
  const factory SalesChartState({
    /// 選択中の表示期間
    required SalesPeriod period,

    /// グラフ描画用の座標リスト
    required List<FlSpot> spots,

    /// X軸に表示する日付ラベルリスト
    required List<String> dateLabels,

    /// Y軸の最大値（見切れ防止マージン込み）
    required double maxY,

    /// 選択期間の合計売上
    required int totalSales,

    /// 選択期間の日別平均売上
    required int dailyAverage,
  }) = _SalesChartState;
}
