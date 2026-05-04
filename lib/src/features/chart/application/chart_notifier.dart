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
    final nextCounter = state.itemCounter + 1;
    state = state.copyWith(
      itemCounter: nextCounter,
      items: [
        ...state.items,
        ChartItem(
          id: const Uuid().v4(),
          label: 'Item$nextCounter',
        ),
      ],
    );
  }

  /// 指定したIDの項目を削除する
  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }

  /// 指定したIDの項目の名前を更新する
  void updateLabel(String id, String label) {
    state = state.copyWith(
      items: state.items.map((item) {
        return item.id == id ? item.copyWith(label: label) : item;
      }).toList(),
    );
  }

  /// 指定したIDの項目の数値を更新する
  void updateValue(String id, double value) {
    state = state.copyWith(
      items: state.items.map((item) {
        return item.id == id ? item.copyWith(value: value) : item;
      }).toList(),
    );
  }
}
