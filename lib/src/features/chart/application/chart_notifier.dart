import 'package:flutter_sample/src/features/chart/application/chart_state.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_item.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'chart_notifier.g.dart';

/// グラフデータの状態を管理するNotifier
@riverpod
class ChartNotifier extends _$ChartNotifier {
  @override
  ChartState build() {
    return const ChartState();
  }

  /// グラフの種類を変更する
  void updateChartType(ChartType type) {
    state = state.copyWith(chartType: type);
  }

  /// 新しい項目を追加する
  void addItem() {
    state = state.copyWith(
      items: [
        ...state.items,
        ChartItem(
          id: const Uuid().v4(),
          label: 'Item${state.items.length + 1}',
        ),
      ],
    );
  }

  /// 指定したインデックスの項目を削除する
  void removeItem(int index) {
    final newItems = List<ChartItem>.from(state.items)..removeAt(index);
    state = state.copyWith(items: newItems);
  }

  /// 項目の名前を更新する
  void updateLabel(int index, String label) {
    final newItems = [...state.items];
    newItems[index] = newItems[index].copyWith(label: label);
    state = state.copyWith(items: newItems);
  }

  /// 項目の数値を更新する
  void updateValue(int index, double value) {
    final newItems = state.items.asMap().entries.map((entry) {
      if (entry.key == index) {
        return entry.value.copyWith(value: value);
      }
      return entry.value;
    }).toList();
    state = state.copyWith(items: newItems);
  }
}
