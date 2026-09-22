// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feature_flags.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeatureFlags {

/// QRコードスキャナー機能の利用可否
 bool get isQrScannerEnabled;/// 動的お知らせバナーのメッセージ（空文字の場合は非表示）
 String get announcementMessage;
/// Create a copy of FeatureFlags
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeatureFlagsCopyWith<FeatureFlags> get copyWith => _$FeatureFlagsCopyWithImpl<FeatureFlags>(this as FeatureFlags, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeatureFlags&&(identical(other.isQrScannerEnabled, isQrScannerEnabled) || other.isQrScannerEnabled == isQrScannerEnabled)&&(identical(other.announcementMessage, announcementMessage) || other.announcementMessage == announcementMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isQrScannerEnabled,announcementMessage);

@override
String toString() {
  return 'FeatureFlags(isQrScannerEnabled: $isQrScannerEnabled, announcementMessage: $announcementMessage)';
}


}

/// @nodoc
abstract mixin class $FeatureFlagsCopyWith<$Res>  {
  factory $FeatureFlagsCopyWith(FeatureFlags value, $Res Function(FeatureFlags) _then) = _$FeatureFlagsCopyWithImpl;
@useResult
$Res call({
 bool isQrScannerEnabled, String announcementMessage
});




}
/// @nodoc
class _$FeatureFlagsCopyWithImpl<$Res>
    implements $FeatureFlagsCopyWith<$Res> {
  _$FeatureFlagsCopyWithImpl(this._self, this._then);

  final FeatureFlags _self;
  final $Res Function(FeatureFlags) _then;

/// Create a copy of FeatureFlags
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isQrScannerEnabled = null,Object? announcementMessage = null,}) {
  return _then(_self.copyWith(
isQrScannerEnabled: null == isQrScannerEnabled ? _self.isQrScannerEnabled : isQrScannerEnabled // ignore: cast_nullable_to_non_nullable
as bool,announcementMessage: null == announcementMessage ? _self.announcementMessage : announcementMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FeatureFlags].
extension FeatureFlagsPatterns on FeatureFlags {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeatureFlags value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeatureFlags() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeatureFlags value)  $default,){
final _that = this;
switch (_that) {
case _FeatureFlags():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeatureFlags value)?  $default,){
final _that = this;
switch (_that) {
case _FeatureFlags() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isQrScannerEnabled,  String announcementMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeatureFlags() when $default != null:
return $default(_that.isQrScannerEnabled,_that.announcementMessage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isQrScannerEnabled,  String announcementMessage)  $default,) {final _that = this;
switch (_that) {
case _FeatureFlags():
return $default(_that.isQrScannerEnabled,_that.announcementMessage);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isQrScannerEnabled,  String announcementMessage)?  $default,) {final _that = this;
switch (_that) {
case _FeatureFlags() when $default != null:
return $default(_that.isQrScannerEnabled,_that.announcementMessage);case _:
  return null;

}
}

}

/// @nodoc


class _FeatureFlags implements FeatureFlags {
  const _FeatureFlags({this.isQrScannerEnabled = true, this.announcementMessage = ''});
  

/// QRコードスキャナー機能の利用可否
@override@JsonKey() final  bool isQrScannerEnabled;
/// 動的お知らせバナーのメッセージ（空文字の場合は非表示）
@override@JsonKey() final  String announcementMessage;

/// Create a copy of FeatureFlags
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeatureFlagsCopyWith<_FeatureFlags> get copyWith => __$FeatureFlagsCopyWithImpl<_FeatureFlags>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeatureFlags&&(identical(other.isQrScannerEnabled, isQrScannerEnabled) || other.isQrScannerEnabled == isQrScannerEnabled)&&(identical(other.announcementMessage, announcementMessage) || other.announcementMessage == announcementMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isQrScannerEnabled,announcementMessage);

@override
String toString() {
  return 'FeatureFlags(isQrScannerEnabled: $isQrScannerEnabled, announcementMessage: $announcementMessage)';
}


}

/// @nodoc
abstract mixin class _$FeatureFlagsCopyWith<$Res> implements $FeatureFlagsCopyWith<$Res> {
  factory _$FeatureFlagsCopyWith(_FeatureFlags value, $Res Function(_FeatureFlags) _then) = __$FeatureFlagsCopyWithImpl;
@override @useResult
$Res call({
 bool isQrScannerEnabled, String announcementMessage
});




}
/// @nodoc
class __$FeatureFlagsCopyWithImpl<$Res>
    implements _$FeatureFlagsCopyWith<$Res> {
  __$FeatureFlagsCopyWithImpl(this._self, this._then);

  final _FeatureFlags _self;
  final $Res Function(_FeatureFlags) _then;

/// Create a copy of FeatureFlags
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isQrScannerEnabled = null,Object? announcementMessage = null,}) {
  return _then(_FeatureFlags(
isQrScannerEnabled: null == isQrScannerEnabled ? _self.isQrScannerEnabled : isQrScannerEnabled // ignore: cast_nullable_to_non_nullable
as bool,announcementMessage: null == announcementMessage ? _self.announcementMessage : announcementMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
