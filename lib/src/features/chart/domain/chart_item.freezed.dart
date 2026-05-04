// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chart_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChartItem {

/// 項目のID（一意のキーとして使用）
 String get id;/// 項目の名前（例: 1月, 食費 など）
 String get label;/// 項目に対応する数値
 double get value;
/// Create a copy of ChartItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartItemCopyWith<ChartItem> get copyWith => _$ChartItemCopyWithImpl<ChartItem>(this as ChartItem, _$identity);

  /// Serializes this ChartItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartItem&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,value);

@override
String toString() {
  return 'ChartItem(id: $id, label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class $ChartItemCopyWith<$Res>  {
  factory $ChartItemCopyWith(ChartItem value, $Res Function(ChartItem) _then) = _$ChartItemCopyWithImpl;
@useResult
$Res call({
 String id, String label, double value
});




}
/// @nodoc
class _$ChartItemCopyWithImpl<$Res>
    implements $ChartItemCopyWith<$Res> {
  _$ChartItemCopyWithImpl(this._self, this._then);

  final ChartItem _self;
  final $Res Function(ChartItem) _then;

/// Create a copy of ChartItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? value = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ChartItem].
extension ChartItemPatterns on ChartItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChartItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChartItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChartItem value)  $default,){
final _that = this;
switch (_that) {
case _ChartItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChartItem value)?  $default,){
final _that = this;
switch (_that) {
case _ChartItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  double value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChartItem() when $default != null:
return $default(_that.id,_that.label,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  double value)  $default,) {final _that = this;
switch (_that) {
case _ChartItem():
return $default(_that.id,_that.label,_that.value);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  double value)?  $default,) {final _that = this;
switch (_that) {
case _ChartItem() when $default != null:
return $default(_that.id,_that.label,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChartItem implements ChartItem {
  const _ChartItem({required this.id, this.label = '', this.value = 0.0});
  factory _ChartItem.fromJson(Map<String, dynamic> json) => _$ChartItemFromJson(json);

/// 項目のID（一意のキーとして使用）
@override final  String id;
/// 項目の名前（例: 1月, 食費 など）
@override@JsonKey() final  String label;
/// 項目に対応する数値
@override@JsonKey() final  double value;

/// Create a copy of ChartItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChartItemCopyWith<_ChartItem> get copyWith => __$ChartItemCopyWithImpl<_ChartItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChartItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChartItem&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,value);

@override
String toString() {
  return 'ChartItem(id: $id, label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class _$ChartItemCopyWith<$Res> implements $ChartItemCopyWith<$Res> {
  factory _$ChartItemCopyWith(_ChartItem value, $Res Function(_ChartItem) _then) = __$ChartItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, double value
});




}
/// @nodoc
class __$ChartItemCopyWithImpl<$Res>
    implements _$ChartItemCopyWith<$Res> {
  __$ChartItemCopyWithImpl(this._self, this._then);

  final _ChartItem _self;
  final $Res Function(_ChartItem) _then;

/// Create a copy of ChartItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? value = null,}) {
  return _then(_ChartItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
