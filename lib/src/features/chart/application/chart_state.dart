import 'package:flutter_sample/src/features/chart/domain/chart_item.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chart_state.freezed.dart';

/// グラフ作成画面の状態を管理するモデル
@freezed
sealed class ChartState with _$ChartState {
  const factory ChartState({
    /// 入力されたデータ項目のリスト
    @Default([
      ChartItem(id: 'item1', label: 'Item1', value: 10),
      ChartItem(id: 'item2', label: 'Item2', value: 20),
    ])
    List<ChartItem> items,

    /// 選択されているグラフの種類
    @Default(ChartType.line) ChartType chartType,

    /// 項目名の連番管理用カウンター（削除されても重複しないように管理）
    @Default(2) int itemCounter,
  }) = _ChartState;
}
