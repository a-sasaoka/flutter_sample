// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Address _$AddressFromJson(Map<String, dynamic> json) => _Address(
  city: json['city'] as String,
  street: json['street'] as String,
  suite: json['suite'] as String,
);

Map<String, dynamic> _$AddressToJson(_Address instance) => <String, dynamic>{
  'city': instance.city,
  'street': instance.street,
  'suite': instance.suite,
};
