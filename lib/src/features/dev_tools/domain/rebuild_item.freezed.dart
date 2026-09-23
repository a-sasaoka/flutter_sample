// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rebuild_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RebuildItem {

 int get id; String get name; String get category; String get description;
/// Create a copy of RebuildItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RebuildItemCopyWith<RebuildItem> get copyWith => _$RebuildItemCopyWithImpl<RebuildItem>(this as RebuildItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RebuildItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,category,description);

@override
String toString() {
  return 'RebuildItem(id: $id, name: $name, category: $category, description: $description)';
}


}

/// @nodoc
abstract mixin class $RebuildItemCopyWith<$Res>  {
  factory $RebuildItemCopyWith(RebuildItem value, $Res Function(RebuildItem) _then) = _$RebuildItemCopyWithImpl;
@useResult
$Res call({
 int id, String name, String category, String description
});




}
/// @nodoc
class _$RebuildItemCopyWithImpl<$Res>
    implements $RebuildItemCopyWith<$Res> {
  _$RebuildItemCopyWithImpl(this._self, this._then);

  final RebuildItem _self;
  final $Res Function(RebuildItem) _then;

/// Create a copy of RebuildItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? category = null,Object? description = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RebuildItem].
extension RebuildItemPatterns on RebuildItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RebuildItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RebuildItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RebuildItem value)  $default,){
final _that = this;
switch (_that) {
case _RebuildItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RebuildItem value)?  $default,){
final _that = this;
switch (_that) {
case _RebuildItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String category,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RebuildItem() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String category,  String description)  $default,) {final _that = this;
switch (_that) {
case _RebuildItem():
return $default(_that.id,_that.name,_that.category,_that.description);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String category,  String description)?  $default,) {final _that = this;
switch (_that) {
case _RebuildItem() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.description);case _:
  return null;

}
}

}

/// @nodoc


class _RebuildItem implements RebuildItem {
  const _RebuildItem({required this.id, required this.name, required this.category, required this.description});
  

@override final  int id;
@override final  String name;
@override final  String category;
@override final  String description;

/// Create a copy of RebuildItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RebuildItemCopyWith<_RebuildItem> get copyWith => __$RebuildItemCopyWithImpl<_RebuildItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RebuildItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,category,description);

@override
String toString() {
  return 'RebuildItem(id: $id, name: $name, category: $category, description: $description)';
}


}

/// @nodoc
abstract mixin class _$RebuildItemCopyWith<$Res> implements $RebuildItemCopyWith<$Res> {
  factory _$RebuildItemCopyWith(_RebuildItem value, $Res Function(_RebuildItem) _then) = __$RebuildItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String category, String description
});




}
/// @nodoc
class __$RebuildItemCopyWithImpl<$Res>
    implements _$RebuildItemCopyWith<$Res> {
  __$RebuildItemCopyWithImpl(this._self, this._then);

  final _RebuildItem _self;
  final $Res Function(_RebuildItem) _then;

/// Create a copy of RebuildItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? category = null,Object? description = null,}) {
  return _then(_RebuildItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
