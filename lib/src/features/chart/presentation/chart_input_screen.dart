import 'package:flutter/material.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/chart/application/chart_notifier.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_type.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// グラフの項目と数値を入力する画面
class ChartInputScreen extends HookConsumerWidget {
  /// コンストラクタ
  const ChartInputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // グラフの種類だけをwatchすることで、項目更新時の再描画を抑制する
    final chartType = ref.watch(chartProvider.select((s) => s.chartType));
    // 項目IDのリストだけをwatchする
    final itemIds = ref.watch(
      chartProvider.select((s) => s.items.map((i) => i.id).toList()),
    );

    final notifier = ref.read(chartProvider.notifier);
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.chartInputTitle),
          actions: [
            // 全削除ボタン
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.chartClearAll),
                    content: Text(l10n.chartClearConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.close),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          l10n.chartClearAll,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  notifier.reset();
                }
              },
              tooltip: l10n.chartClearAll,
            ),
            // グラフ表示画面への遷移ボタンをAppBarに配置（FABの重複を避ける）
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                const ChartDisplayRoute().go(context);
              },
              tooltip: l10n.chartViewGraph,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // グラフ種類の選択
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<ChartType>(
                segments: ChartType.values
                    .map(
                      (type) => ButtonSegment(
                        value: type,
                        label: Text(type.getLocalizedLabel(l10n)),
                        icon: Icon(_getChartIcon(type)),
                      ),
                    )
                    .toList(),
                selected: {chartType},
                onSelectionChanged: (selection) {
                  notifier.updateChartType(selection.first);
                },
              ),
            ),
            const Divider(height: 1),
            // 入力リスト
            Expanded(
              child: itemIds.isEmpty
                  ? Center(
                      child: Text(
                        l10n.chartNoData,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: itemIds.length,
                      itemBuilder: (context, index) {
                        final id = itemIds[index];
                        return _ChartItemInput(
                          key: ValueKey(id),
                          id: id,
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: notifier.addItem,
          icon: const Icon(Icons.add),
          label: Text(l10n.chartAddItem),
        ),
      ),
    );
  }

  IconData _getChartIcon(ChartType type) {
    switch (type) {
      case ChartType.line:
        return Icons.show_chart;
      case ChartType.bar:
        return Icons.bar_chart;
      case ChartType.pie:
        return Icons.pie_chart_outline;
    }
  }
}

/// 個別の項目入力用ウィジェット（再描画最適化のため分割）
class _ChartItemInput extends ConsumerWidget {
  const _ChartItemInput({
    required this.id,
    super.key,
  });

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // この項目に関連するデータのみをwatchする
    final item = ref.watch(
      chartProvider.select(
        (s) => s.items.where((i) => i.id == id).firstOrNull,
      ),
    );

    // 削除直後などはitemがnullになる可能性があるため、その場合は空のウィジェットを返す
    if (item == null) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(chartProvider.notifier);
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(
          children: [
            // 項目名入力
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: item.label,
                decoration: InputDecoration(
                  labelText: l10n.chartItemLabel,
                  prefixIcon: const Icon(Icons.label_outline, size: 20),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) => notifier.updateLabel(id, value),
              ),
            ),
            const SizedBox(width: 12),
            // 数値入力
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: item.value.toString(),
                decoration: InputDecoration(
                  labelText: l10n.chartItemValue,
                  prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  final doubleValue = double.tryParse(value) ?? 0.0;
                  notifier.updateValue(id, doubleValue);
                },
              ),
            ),
            // 削除ボタン
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.7),
              ),
              onPressed: () => notifier.removeItem(id),
            ),
          ],
        ),
      ),
    );
  }
}
