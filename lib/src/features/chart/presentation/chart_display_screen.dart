import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

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
                          child: _buildChart(state),
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
                        final color = _colors[index % _colors.length];
                        return Card(
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

  Widget _buildChart(ChartState state) {
    switch (state.chartType) {
      case ChartType.line:
        return _buildLineChart(state);
      case ChartType.bar:
        return _buildBarChart(state);
      case ChartType.pie:
        return _buildPieChart(state);
    }
  }

  /// 項目数に応じてラベルの間欠表示間隔を計算する
  int _getLabelInterval(int itemCount) {
    if (itemCount > 20) return 5;
    if (itemCount > 10) return 2;
    return 1;
  }

  Widget _buildLineChart(ChartState state) {
    final labelInterval = _getLabelInterval(state.items.length);

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
            spots: state.items.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(ChartState state) {
    // 項目数に応じて棒の太さを調整
    final barWidth = state.items.length > 20
        ? 4.0
        : (state.items.length > 10 ? 8.0 : 16.0);

    final labelInterval = _getLabelInterval(state.items.length);

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
        barGroups: state.items.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: Colors.green,
                width: barWidth,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  static final List<MaterialColor> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

  Widget _buildPieChart(ChartState state) {
    return PieChart(
      PieChartData(
        sections: state.items.asMap().entries.map((entry) {
          final color = _colors[entry.key % _colors.length];
          return PieChartSectionData(
            value: entry.value.value,
            title: entry.value.label,
            color: color,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }
}
