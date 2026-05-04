import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.chartInputTitle),
          actions: [
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
                      ),
                    )
                    .toList(),
                selected: {chartType},
                onSelectionChanged: (selection) {
                  notifier.updateChartType(selection.first);
                },
              ),
            ),
            const Divider(),
            // 入力リスト
            Expanded(
              child: ListView.builder(
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
        floatingActionButton: FloatingActionButton(
          onPressed: notifier.addItem,
          tooltip: l10n.chartAddItem,
          child: const Icon(Icons.add),
        ),
      ),
    );
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
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        children: [
          // 項目名入力
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: item.label,
              decoration: InputDecoration(
                labelText: l10n.chartItemLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => notifier.updateLabel(id, value),
            ),
          ),
          const SizedBox(width: 8),
          // 数値入力
          Expanded(
            child: TextFormField(
              initialValue: item.value.toString(),
              decoration: InputDecoration(
                labelText: l10n.chartItemValue,
                border: const OutlineInputBorder(),
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
            icon: const Icon(Icons.delete),
            onPressed: () => notifier.removeItem(id),
          ),
        ],
      ),
    );
  }
}
