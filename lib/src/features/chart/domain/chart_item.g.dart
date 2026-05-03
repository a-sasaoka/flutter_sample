// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chart_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChartItem _$ChartItemFromJson(Map<String, dynamic> json) => _ChartItem(
  id: json['id'] as String,
  label: json['label'] as String? ?? '',
  value: (json['value'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$ChartItemToJson(_ChartItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'value': instance.value,
    };
