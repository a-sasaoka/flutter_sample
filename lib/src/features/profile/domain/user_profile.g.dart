// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  name: json['name'] as String,
  email: json['email'] as String,
  displayName: json['displayName'] as String? ?? '',
  phone: json['phone'] as String? ?? '',
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'displayName': instance.displayName,
      'phone': instance.phone,
    };
