import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/chart/presentation/controllers/sales_chart_state.dart';
import 'package:intl/intl.dart';

/// 📈 スムーズなアニメーションとカスタムTooltipを備えた売上推移折れ線グラフ
class AnimatedSalesChart extends StatelessWidget {
  /// コンストラクタ
  const AnimatedSalesChart({required this.state, super.key});

  /// 表示するグラフの状態データ
  final SalesChartState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    // 日本円表記用のフォーマッター（例: ¥12,500）
    final currencyFormatter = NumberFormat.currency(
      locale: 'ja_JP',
      symbol: '¥',
      decimalDigits: 0,
    );

    // 14日間表示の時は日付が重ならないように2日おきに表示
    final labelInterval = state.period == SalesPeriod.days14 ? 2 : 1;

    return LineChart(
      LineChartData(
        // グラフ端のドットが見切れないように少しだけ左右にマージン（余裕）を設定
        minX: -0.2,
        maxX: (state.spots.length - 1).toDouble() + 0.2,
        maxY: state.maxY,

        // グリッド線（横線のみ薄く表示して見やすくする）
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: state.maxY / 4 > 0
              ? (state.maxY / 4).floorToDouble()
              : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),

        // 外枠の線（下と左の軸線のみ表示）
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            left: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),

        // 軸の目盛りラベル
        titlesData: FlTitlesData(
          // 上と右のラベルは非表示
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),

          // 左側のY軸ラベル（金額）
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: state.maxY / 4 > 0
                  ? (state.maxY / 4).floorToDouble()
                  : 1,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const SizedBox.shrink();
                }
                // 1万円単位（10k, 20kなど）または簡潔な表記
                final formatted = value >= 1000
                    ? '${(value / 1000).toStringAsFixed(0)}k'
                    : value.toInt().toString();
                return Text(
                  formatted,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),

          // 下側のX軸ラベル（日付）
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                // 整数かつ範囲内のインデックスで、間隔条件を満たす場合のみ表示
                if (value != index ||
                    index < 0 ||
                    index >= state.dateLabels.length) {
                  return const SizedBox.shrink();
                }
                if (index % labelInterval != 0) {
                  return const SizedBox.shrink();
                }

                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    state.dateLabels[index],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // タッチ時のツールチップ（吹き出し）設定
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => theme.colorScheme.inverseSurface,
            tooltipBorderRadius: BorderRadius.circular(8),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final dateText = (index >= 0 && index < state.dateLabels.length)
                    ? state.dateLabels[index]
                    : '';
                final amountText = currencyFormatter.format(spot.y.toInt());

                return LineTooltipItem(
                  '$dateText\n$amountText',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),

        // 折れ線グラフ本体
        lineBarsData: [
          LineChartBarData(
            spots: state.spots,
            isCurved: true, // 滑らかな曲線
            curveSmoothness: 0.3,
            color: primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            // 各日のポイント（丸いドット）
            dotData: FlDotData(
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: primaryColor,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                );
              },
            ),
            // 折れ線の下側をグラデーションで塗りつぶす
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.3),
                  primaryColor.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
      // 期間切り替え時のスムーズなアニメーション設定
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }
}
