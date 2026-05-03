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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: _buildChart(state),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // データ一覧の簡易表示
            Expanded(
              child: ListView.builder(
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return ListTile(
                    title: Text(item.label),
                    trailing: Text(
                      item.value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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

  Widget _buildLineChart(ChartState state) {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < state.items.length) {
                  return Text(state.items[index].label);
                }
                return const Text('');
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
    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < state.items.length) {
                  return Text(state.items[index].label);
                }
                return const Text('');
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
                width: 16,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart(ChartState state) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    return PieChart(
      PieChartData(
        sections: state.items.asMap().entries.map((entry) {
          final color = colors[entry.key % colors.length];
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
