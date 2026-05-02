// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'memo_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MemoModel {

 String get id; String get title; String get content; DateTime get createdAt; DateTime get updatedAt; bool get isDeleted; bool get isSynced;
/// Create a copy of MemoModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemoModelCopyWith<MemoModel> get copyWith => _$MemoModelCopyWithImpl<MemoModel>(this as MemoModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemoModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,content,createdAt,updatedAt,isDeleted,isSynced);

@override
String toString() {
  return 'MemoModel(id: $id, title: $title, content: $content, createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class $MemoModelCopyWith<$Res>  {
  factory $MemoModelCopyWith(MemoModel value, $Res Function(MemoModel) _then) = _$MemoModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String content, DateTime createdAt, DateTime updatedAt, bool isDeleted, bool isSynced
});




}
/// @nodoc
class _$MemoModelCopyWithImpl<$Res>
    implements $MemoModelCopyWith<$Res> {
  _$MemoModelCopyWithImpl(this._self, this._then);

  final MemoModel _self;
  final $Res Function(MemoModel) _then;

/// Create a copy of MemoModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? content = null,Object? createdAt = null,Object? updatedAt = null,Object? isDeleted = null,Object? isSynced = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MemoModel].
extension MemoModelPatterns on MemoModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemoModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemoModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemoModel value)  $default,){
final _that = this;
switch (_that) {
case _MemoModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemoModel value)?  $default,){
final _that = this;
switch (_that) {
case _MemoModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String content,  DateTime createdAt,  DateTime updatedAt,  bool isDeleted,  bool isSynced)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemoModel() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.createdAt,_that.updatedAt,_that.isDeleted,_that.isSynced);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String content,  DateTime createdAt,  DateTime updatedAt,  bool isDeleted,  bool isSynced)  $default,) {final _that = this;
switch (_that) {
case _MemoModel():
return $default(_that.id,_that.title,_that.content,_that.createdAt,_that.updatedAt,_that.isDeleted,_that.isSynced);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String content,  DateTime createdAt,  DateTime updatedAt,  bool isDeleted,  bool isSynced)?  $default,) {final _that = this;
switch (_that) {
case _MemoModel() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.createdAt,_that.updatedAt,_that.isDeleted,_that.isSynced);case _:
  return null;

}
}

}

/// @nodoc


class _MemoModel implements MemoModel {
  const _MemoModel({required this.id, required this.title, required this.content, required this.createdAt, required this.updatedAt, this.isDeleted = false, this.isSynced = false});
  

@override final  String id;
@override final  String title;
@override final  String content;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  bool isDeleted;
@override@JsonKey() final  bool isSynced;

/// Create a copy of MemoModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemoModelCopyWith<_MemoModel> get copyWith => __$MemoModelCopyWithImpl<_MemoModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemoModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,content,createdAt,updatedAt,isDeleted,isSynced);

@override
String toString() {
  return 'MemoModel(id: $id, title: $title, content: $content, createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class _$MemoModelCopyWith<$Res> implements $MemoModelCopyWith<$Res> {
  factory _$MemoModelCopyWith(_MemoModel value, $Res Function(_MemoModel) _then) = __$MemoModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String content, DateTime createdAt, DateTime updatedAt, bool isDeleted, bool isSynced
});




}
/// @nodoc
class __$MemoModelCopyWithImpl<$Res>
    implements _$MemoModelCopyWith<$Res> {
  __$MemoModelCopyWithImpl(this._self, this._then);

  final _MemoModel _self;
  final $Res Function(_MemoModel) _then;

/// Create a copy of MemoModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? content = null,Object? createdAt = null,Object? updatedAt = null,Object? isDeleted = null,Object? isSynced = null,}) {
  return _then(_MemoModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
