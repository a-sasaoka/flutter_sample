// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdateInfo _$UpdateInfoFromJson(Map<String, dynamic> json) => _UpdateInfo(
  requiredVersion: json['requiredVersion'] as String,
  enabledAt: DateTime.parse(json['enabledAt'] as String),
  canCancel: json['canCancel'] as bool? ?? false,
);

Map<String, dynamic> _$UpdateInfoToJson(_UpdateInfo instance) =>
    <String, dynamic>{
      'requiredVersion': instance.requiredVersion,
      'enabledAt': instance.enabledAt.toIso8601String(),
      'canCancel': instance.canCancel,
    };
