// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rebuild_demo_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RebuildDemoState {

 bool get isOptimized; String get searchQuery; List<RebuildItem> get items;
/// Create a copy of RebuildDemoState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RebuildDemoStateCopyWith<RebuildDemoState> get copyWith => _$RebuildDemoStateCopyWithImpl<RebuildDemoState>(this as RebuildDemoState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RebuildDemoState&&(identical(other.isOptimized, isOptimized) || other.isOptimized == isOptimized)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,isOptimized,searchQuery,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'RebuildDemoState(isOptimized: $isOptimized, searchQuery: $searchQuery, items: $items)';
}


}

/// @nodoc
abstract mixin class $RebuildDemoStateCopyWith<$Res>  {
  factory $RebuildDemoStateCopyWith(RebuildDemoState value, $Res Function(RebuildDemoState) _then) = _$RebuildDemoStateCopyWithImpl;
@useResult
$Res call({
 bool isOptimized, String searchQuery, List<RebuildItem> items
});




}
/// @nodoc
class _$RebuildDemoStateCopyWithImpl<$Res>
    implements $RebuildDemoStateCopyWith<$Res> {
  _$RebuildDemoStateCopyWithImpl(this._self, this._then);

  final RebuildDemoState _self;
  final $Res Function(RebuildDemoState) _then;

/// Create a copy of RebuildDemoState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isOptimized = null,Object? searchQuery = null,Object? items = null,}) {
  return _then(_self.copyWith(
isOptimized: null == isOptimized ? _self.isOptimized : isOptimized // ignore: cast_nullable_to_non_nullable
as bool,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<RebuildItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [RebuildDemoState].
extension RebuildDemoStatePatterns on RebuildDemoState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RebuildDemoState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RebuildDemoState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RebuildDemoState value)  $default,){
final _that = this;
switch (_that) {
case _RebuildDemoState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RebuildDemoState value)?  $default,){
final _that = this;
switch (_that) {
case _RebuildDemoState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isOptimized,  String searchQuery,  List<RebuildItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RebuildDemoState() when $default != null:
return $default(_that.isOptimized,_that.searchQuery,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isOptimized,  String searchQuery,  List<RebuildItem> items)  $default,) {final _that = this;
switch (_that) {
case _RebuildDemoState():
return $default(_that.isOptimized,_that.searchQuery,_that.items);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isOptimized,  String searchQuery,  List<RebuildItem> items)?  $default,) {final _that = this;
switch (_that) {
case _RebuildDemoState() when $default != null:
return $default(_that.isOptimized,_that.searchQuery,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _RebuildDemoState extends RebuildDemoState {
  const _RebuildDemoState({required this.isOptimized, required this.searchQuery, required final  List<RebuildItem> items}): _items = items,super._();
  

@override final  bool isOptimized;
@override final  String searchQuery;
 final  List<RebuildItem> _items;
@override List<RebuildItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of RebuildDemoState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RebuildDemoStateCopyWith<_RebuildDemoState> get copyWith => __$RebuildDemoStateCopyWithImpl<_RebuildDemoState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RebuildDemoState&&(identical(other.isOptimized, isOptimized) || other.isOptimized == isOptimized)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,isOptimized,searchQuery,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'RebuildDemoState(isOptimized: $isOptimized, searchQuery: $searchQuery, items: $items)';
}


}

/// @nodoc
abstract mixin class _$RebuildDemoStateCopyWith<$Res> implements $RebuildDemoStateCopyWith<$Res> {
  factory _$RebuildDemoStateCopyWith(_RebuildDemoState value, $Res Function(_RebuildDemoState) _then) = __$RebuildDemoStateCopyWithImpl;
@override @useResult
$Res call({
 bool isOptimized, String searchQuery, List<RebuildItem> items
});




}
/// @nodoc
class __$RebuildDemoStateCopyWithImpl<$Res>
    implements _$RebuildDemoStateCopyWith<$Res> {
  __$RebuildDemoStateCopyWithImpl(this._self, this._then);

  final _RebuildDemoState _self;
  final $Res Function(_RebuildDemoState) _then;

/// Create a copy of RebuildDemoState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isOptimized = null,Object? searchQuery = null,Object? items = null,}) {
  return _then(_RebuildDemoState(
isOptimized: null == isOptimized ? _self.isOptimized : isOptimized // ignore: cast_nullable_to_non_nullable
as bool,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<RebuildItem>,
  ));
}


}

// dart format on
