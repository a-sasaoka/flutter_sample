// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qr_scan_history_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QrScanHistoryModel {

 int get id; String get rawValue; DateTime get scannedAt;
/// Create a copy of QrScanHistoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QrScanHistoryModelCopyWith<QrScanHistoryModel> get copyWith => _$QrScanHistoryModelCopyWithImpl<QrScanHistoryModel>(this as QrScanHistoryModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrScanHistoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.rawValue, rawValue) || other.rawValue == rawValue)&&(identical(other.scannedAt, scannedAt) || other.scannedAt == scannedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,rawValue,scannedAt);

@override
String toString() {
  return 'QrScanHistoryModel(id: $id, rawValue: $rawValue, scannedAt: $scannedAt)';
}


}

/// @nodoc
abstract mixin class $QrScanHistoryModelCopyWith<$Res>  {
  factory $QrScanHistoryModelCopyWith(QrScanHistoryModel value, $Res Function(QrScanHistoryModel) _then) = _$QrScanHistoryModelCopyWithImpl;
@useResult
$Res call({
 int id, String rawValue, DateTime scannedAt
});




}
/// @nodoc
class _$QrScanHistoryModelCopyWithImpl<$Res>
    implements $QrScanHistoryModelCopyWith<$Res> {
  _$QrScanHistoryModelCopyWithImpl(this._self, this._then);

  final QrScanHistoryModel _self;
  final $Res Function(QrScanHistoryModel) _then;

/// Create a copy of QrScanHistoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? rawValue = null,Object? scannedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,rawValue: null == rawValue ? _self.rawValue : rawValue // ignore: cast_nullable_to_non_nullable
as String,scannedAt: null == scannedAt ? _self.scannedAt : scannedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [QrScanHistoryModel].
extension QrScanHistoryModelPatterns on QrScanHistoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QrScanHistoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QrScanHistoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QrScanHistoryModel value)  $default,){
final _that = this;
switch (_that) {
case _QrScanHistoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QrScanHistoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _QrScanHistoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String rawValue,  DateTime scannedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QrScanHistoryModel() when $default != null:
return $default(_that.id,_that.rawValue,_that.scannedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String rawValue,  DateTime scannedAt)  $default,) {final _that = this;
switch (_that) {
case _QrScanHistoryModel():
return $default(_that.id,_that.rawValue,_that.scannedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String rawValue,  DateTime scannedAt)?  $default,) {final _that = this;
switch (_that) {
case _QrScanHistoryModel() when $default != null:
return $default(_that.id,_that.rawValue,_that.scannedAt);case _:
  return null;

}
}

}

/// @nodoc


class _QrScanHistoryModel implements QrScanHistoryModel {
  const _QrScanHistoryModel({required this.id, required this.rawValue, required this.scannedAt});
  

@override final  int id;
@override final  String rawValue;
@override final  DateTime scannedAt;

/// Create a copy of QrScanHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QrScanHistoryModelCopyWith<_QrScanHistoryModel> get copyWith => __$QrScanHistoryModelCopyWithImpl<_QrScanHistoryModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QrScanHistoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.rawValue, rawValue) || other.rawValue == rawValue)&&(identical(other.scannedAt, scannedAt) || other.scannedAt == scannedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,rawValue,scannedAt);

@override
String toString() {
  return 'QrScanHistoryModel(id: $id, rawValue: $rawValue, scannedAt: $scannedAt)';
}


}

/// @nodoc
abstract mixin class _$QrScanHistoryModelCopyWith<$Res> implements $QrScanHistoryModelCopyWith<$Res> {
  factory _$QrScanHistoryModelCopyWith(_QrScanHistoryModel value, $Res Function(_QrScanHistoryModel) _then) = __$QrScanHistoryModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String rawValue, DateTime scannedAt
});




}
/// @nodoc
class __$QrScanHistoryModelCopyWithImpl<$Res>
    implements _$QrScanHistoryModelCopyWith<$Res> {
  __$QrScanHistoryModelCopyWithImpl(this._self, this._then);

  final _QrScanHistoryModel _self;
  final $Res Function(_QrScanHistoryModel) _then;

/// Create a copy of QrScanHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? rawValue = null,Object? scannedAt = null,}) {
  return _then(_QrScanHistoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,rawValue: null == rawValue ? _self.rawValue : rawValue // ignore: cast_nullable_to_non_nullable
as String,scannedAt: null == scannedAt ? _self.scannedAt : scannedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
