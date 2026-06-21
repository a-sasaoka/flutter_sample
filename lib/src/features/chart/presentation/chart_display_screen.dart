import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/chart/application/chart_notifier.dart';
import 'package:flutter_sample/src/features/chart/application/chart_state.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_type.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// グラフを表示する画面
class ChartDisplayScreen extends ConsumerWidget {
  /// コンストラクタ
  const ChartDisplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chartProvider);
    final l10n = context.l10n;
    final palette = AppTheme.chartColors(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.chartDisplayTitle(state.chartType.getLocalizedLabel(l10n)),
        ),
      ),
      body: state.items.isEmpty
          ? Center(
              child: Text(
                l10n.chartNoData,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1.5,
                          child: _ChartSelector(state: state),
                        ),
                        const SizedBox(height: 40),
                        const Divider(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.list_alt_outlined),
                            const SizedBox(width: 8),
                            Text(
                              l10n.chartDataList,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = state.items[index];
                        final color = palette[index % palette.length];
                        return Card(
                          key: ValueKey(item.id),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(
                              item.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              item.value.toString(),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                            ),
                          ),
                        );
                      },
                      childCount: state.items.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// 表示するグラフの種類を判定して切り替える Widget
class _ChartSelector extends StatelessWidget {
  const _ChartSelector({required this.state});

  final ChartState state;

  @override
  Widget build(BuildContext context) {
    switch (state.chartType) {
      case ChartType.line:
        return _LineChartView(state: state);
      case ChartType.bar:
        return _BarChartView(state: state);
      case ChartType.pie:
        return _PieChartView(state: state);
    }
  }
}

/// 項目数に応じてラベルの間欠表示間隔を計算する
int _getLabelInterval(int itemCount) {
  if (itemCount > 20) return 5;
  if (itemCount > 10) return 2;
  return 1;
}

/// 折れ線グラフを描画する Widget
class _LineChartView extends StatelessWidget {
  const _LineChartView({required this.state});

  final ChartState state;

  @override
  Widget build(BuildContext context) {
    final labelInterval = _getLabelInterval(state.items.length);
    final palette = AppTheme.chartColors(context);
    final theme = Theme.of(context);

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60, // 傾けたラベル用に少し広めに確保
              getTitlesWidget: (value, meta) {
                if (value != value.toInt()) {
                  return const SizedBox.shrink();
                }
                final index = value.toInt();

                // 間引きのロジック
                if (index % labelInterval != 0) {
                  return const SizedBox.shrink();
                }

                if (index >= 0 && index < state.items.length) {
                  return SideTitleWidget(
                    meta: meta,
                    angle: -0.5, // 文字が重ならないように少し傾ける
                    space: 12, // 軸との間にスペースを空ける
                    child: Text(
                      state.items[index].label,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (final (i, item) in state.items.indexed)
                FlSpot(i.toDouble(), item.value),
            ],
            isCurved: true,
            color: theme.colorScheme.outlineVariant,
            barWidth: 4,
            dotData: FlDotData(
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: palette[index % palette.length],
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 棒グラフを描画する Widget
class _BarChartView extends StatelessWidget {
  const _BarChartView({required this.state});

  final ChartState state;

  @override
  Widget build(BuildContext context) {
    // 項目数に応じて棒の太さを調整
    final barWidth = state.items.length > 20
        ? 4.0
        : (state.items.length > 10 ? 8.0 : 16.0);

    final labelInterval = _getLabelInterval(state.items.length);
    final palette = AppTheme.chartColors(context);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60, // 傾けたラベル用に少し広めに確保
              getTitlesWidget: (value, meta) {
                if (value != value.toInt()) {
                  return const SizedBox.shrink();
                }
                final index = value.toInt();

                // 間引きのロジック
                if (index % labelInterval != 0) {
                  return const SizedBox.shrink();
                }

                if (index >= 0 && index < state.items.length) {
                  return SideTitleWidget(
                    meta: meta,
                    angle: -0.5, // 文字が重ならないように少し傾ける
                    space: 12, // 軸との間にスペースを空ける
                    child: Text(
                      state.items[index].label,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        barGroups: [
          for (final (i, item) in state.items.indexed)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: item.value,
                  color: palette[i % palette.length], // アイテムごとに色を塗り分ける
                  width: barWidth,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 円グラフを描画する Widget
class _PieChartView extends StatelessWidget {
  const _PieChartView({required this.state});

  final ChartState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.chartColors(context);

    return PieChart(
      PieChartData(
        sections: [
          for (final (i, item) in state.items.indexed)
            () {
              final sectionColor = palette[i % palette.length];
              final textColor = sectionColor.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white;

              return PieChartSectionData(
                value: item.value,
                title: item.label,
                color: sectionColor,
                radius: 50,
                titleStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              );
            }(),
        ],
      ),
    );
  }
}
