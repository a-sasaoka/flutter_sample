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
    final state = ref.watch(chartProvider);
    final notifier = ref.read(chartProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.chartInputTitle),
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
                selected: {state.chartType},
                onSelectionChanged: (selection) {
                  notifier.updateChartType(selection.first);
                },
              ),
            ),
            const Divider(),
            // 入力リスト
            Expanded(
              child: ListView.builder(
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return Padding(
                    key: ValueKey(item.id),
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
                            onChanged: (value) =>
                                notifier.updateLabel(index, value),
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
                              notifier.updateValue(index, doubleValue);
                            },
                          ),
                        ),
                        // 削除ボタン
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => notifier.removeItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 項目追加ボタン
            FloatingActionButton(
              heroTag: 'add',
              onPressed: notifier.addItem,
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 16),
            // グラフ表示画面への遷移ボタン
            FloatingActionButton.extended(
              heroTag: 'view',
              onPressed: () {
                const ChartDisplayRoute().go(context);
              },
              label: Text(l10n.chartViewGraph),
              icon: const Icon(Icons.bar_chart),
            ),
          ],
        ),
      ),
    );
  }
}
