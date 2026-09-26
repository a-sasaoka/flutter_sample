import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/chart/presentation/controllers/sales_chart_controller.dart';
import 'package:flutter_sample/src/features/chart/presentation/controllers/sales_chart_state.dart';
import 'package:flutter_sample/src/features/chart/presentation/widgets/animated_sales_chart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

/// 📈 売上推移チャート画面
class SalesChartScreen extends ConsumerWidget {
  /// コンストラクタ
  const SalesChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salesChartControllerProvider);
    final l10n = context.l10n;
    final currencyFormatter = NumberFormat.currency(
      locale: 'ja_JP',
      symbol: '¥',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.salesChartTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 期間切り替え（7日間 / 14日間）ボタングループ
            SegmentedButton<SalesPeriod>(
              segments: [
                ButtonSegment(
                  value: SalesPeriod.days7,
                  label: Text(l10n.salesChartPeriod7Days),
                  icon: const Icon(Icons.calendar_view_week),
                ),
                ButtonSegment(
                  value: SalesPeriod.days14,
                  label: Text(l10n.salesChartPeriod14Days),
                  icon: const Icon(Icons.date_range),
                ),
              ],
              selected: {state.period},
              onSelectionChanged: (newSelection) {
                ref
                    .read(salesChartControllerProvider.notifier)
                    .switchPeriod(newSelection.first);
              },
            ),
            const SizedBox(height: 16),

            // 売上サマリーカード（合計売上・日別平均）
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: l10n.salesChartTotalSales,
                    value: currencyFormatter.format(state.totalSales),
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: l10n.salesChartDailyAverage,
                    value: currencyFormatter.format(state.dailyAverage),
                    icon: Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 折れ線グラフカード
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: AnimatedSalesChart(state: state),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📊 売上サマリー情報を表示するカード
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
