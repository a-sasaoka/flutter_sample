import 'package:freezed_annotation/freezed_annotation.dart';

part 'chart_item.freezed.dart';
part 'chart_item.g.dart';

/// グラフの1項目（ラベルと数値）を保持するデータモデル
@freezed
sealed class ChartItem with _$ChartItem {
  const factory ChartItem({
    /// 項目のID（一意のキーとして使用）
    required String id,

    /// 項目の名前（例: 1月, 食費 など）
    @Default('') String label,

    /// 項目に対応する数値
    @Default(0.0) double value,
  }) = _ChartItem;

  factory ChartItem.fromJson(Map<String, dynamic> json) =>
      _$ChartItemFromJson(json);
}
