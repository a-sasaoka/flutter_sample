// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MapSearchState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapSearchState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MapSearchState()';
}


}

/// @nodoc
class $MapSearchStateCopyWith<$Res>  {
$MapSearchStateCopyWith(MapSearchState _, $Res Function(MapSearchState) __);
}


/// Adds pattern-matching-related methods to [MapSearchState].
extension MapSearchStatePatterns on MapSearchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MapSearchStateInitial value)?  initial,TResult Function( MapSearchStateLoading value)?  loading,TResult Function( MapSearchStateSuccess value)?  success,TResult Function( MapSearchStateEmpty value)?  empty,TResult Function( MapSearchStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MapSearchStateInitial() when initial != null:
return initial(_that);case MapSearchStateLoading() when loading != null:
return loading(_that);case MapSearchStateSuccess() when success != null:
return success(_that);case MapSearchStateEmpty() when empty != null:
return empty(_that);case MapSearchStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MapSearchStateInitial value)  initial,required TResult Function( MapSearchStateLoading value)  loading,required TResult Function( MapSearchStateSuccess value)  success,required TResult Function( MapSearchStateEmpty value)  empty,required TResult Function( MapSearchStateError value)  error,}){
final _that = this;
switch (_that) {
case MapSearchStateInitial():
return initial(_that);case MapSearchStateLoading():
return loading(_that);case MapSearchStateSuccess():
return success(_that);case MapSearchStateEmpty():
return empty(_that);case MapSearchStateError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MapSearchStateInitial value)?  initial,TResult? Function( MapSearchStateLoading value)?  loading,TResult? Function( MapSearchStateSuccess value)?  success,TResult? Function( MapSearchStateEmpty value)?  empty,TResult? Function( MapSearchStateError value)?  error,}){
final _that = this;
switch (_that) {
case MapSearchStateInitial() when initial != null:
return initial(_that);case MapSearchStateLoading() when loading != null:
return loading(_that);case MapSearchStateSuccess() when success != null:
return success(_that);case MapSearchStateEmpty() when empty != null:
return empty(_that);case MapSearchStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Location> locations,  String query)?  success,TResult Function( String query)?  empty,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MapSearchStateInitial() when initial != null:
return initial();case MapSearchStateLoading() when loading != null:
return loading();case MapSearchStateSuccess() when success != null:
return success(_that.locations,_that.query);case MapSearchStateEmpty() when empty != null:
return empty(_that.query);case MapSearchStateError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Location> locations,  String query)  success,required TResult Function( String query)  empty,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case MapSearchStateInitial():
return initial();case MapSearchStateLoading():
return loading();case MapSearchStateSuccess():
return success(_that.locations,_that.query);case MapSearchStateEmpty():
return empty(_that.query);case MapSearchStateError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Location> locations,  String query)?  success,TResult? Function( String query)?  empty,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case MapSearchStateInitial() when initial != null:
return initial();case MapSearchStateLoading() when loading != null:
return loading();case MapSearchStateSuccess() when success != null:
return success(_that.locations,_that.query);case MapSearchStateEmpty() when empty != null:
return empty(_that.query);case MapSearchStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class MapSearchStateInitial implements MapSearchState {
  const MapSearchStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapSearchStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MapSearchState.initial()';
}


}




/// @nodoc


class MapSearchStateLoading implements MapSearchState {
  const MapSearchStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapSearchStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MapSearchState.loading()';
}


}




/// @nodoc


class MapSearchStateSuccess implements MapSearchState {
  const MapSearchStateSuccess({required final  List<Location> locations, required this.query}): _locations = locations;
  

 final  List<Location> _locations;
 List<Location> get locations {
  if (_locations is EqualUnmodifiableListView) return _locations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_locations);
}

 final  String query;

/// Create a copy of MapSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapSearchStateSuccessCopyWith<MapSearchStateSuccess> get copyWith => _$MapSearchStateSuccessCopyWithImpl<MapSearchStateSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapSearchStateSuccess&&const DeepCollectionEquality().equals(other._locations, _locations)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_locations),query);

@override
String toString() {
  return 'MapSearchState.success(locations: $locations, query: $query)';
}


}

/// @nodoc
abstract mixin class $MapSearchStateSuccessCopyWith<$Res> implements $MapSearchStateCopyWith<$Res> {
  factory $MapSearchStateSuccessCopyWith(MapSearchStateSuccess value, $Res Function(MapSearchStateSuccess) _then) = _$MapSearchStateSuccessCopyWithImpl;
@useResult
$Res call({
 List<Location> locations, String query
});




}
/// @nodoc
class _$MapSearchStateSuccessCopyWithImpl<$Res>
    implements $MapSearchStateSuccessCopyWith<$Res> {
  _$MapSearchStateSuccessCopyWithImpl(this._self, this._then);

  final MapSearchStateSuccess _self;
  final $Res Function(MapSearchStateSuccess) _then;

/// Create a copy of MapSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? locations = null,Object? query = null,}) {
  return _then(MapSearchStateSuccess(
locations: null == locations ? _self._locations : locations // ignore: cast_nullable_to_non_nullable
as List<Location>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MapSearchStateEmpty implements MapSearchState {
  const MapSearchStateEmpty({required this.query});
  

 final  String query;

/// Create a copy of MapSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapSearchStateEmptyCopyWith<MapSearchStateEmpty> get copyWith => _$MapSearchStateEmptyCopyWithImpl<MapSearchStateEmpty>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapSearchStateEmpty&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'MapSearchState.empty(query: $query)';
}


}

/// @nodoc
abstract mixin class $MapSearchStateEmptyCopyWith<$Res> implements $MapSearchStateCopyWith<$Res> {
  factory $MapSearchStateEmptyCopyWith(MapSearchStateEmpty value, $Res Function(MapSearchStateEmpty) _then) = _$MapSearchStateEmptyCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class _$MapSearchStateEmptyCopyWithImpl<$Res>
    implements $MapSearchStateEmptyCopyWith<$Res> {
  _$MapSearchStateEmptyCopyWithImpl(this._self, this._then);

  final MapSearchStateEmpty _self;
  final $Res Function(MapSearchStateEmpty) _then;

/// Create a copy of MapSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(MapSearchStateEmpty(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MapSearchStateError implements MapSearchState {
  const MapSearchStateError(this.message);
  

 final  String message;

/// Create a copy of MapSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapSearchStateErrorCopyWith<MapSearchStateError> get copyWith => _$MapSearchStateErrorCopyWithImpl<MapSearchStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapSearchStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'MapSearchState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $MapSearchStateErrorCopyWith<$Res> implements $MapSearchStateCopyWith<$Res> {
  factory $MapSearchStateErrorCopyWith(MapSearchStateError value, $Res Function(MapSearchStateError) _then) = _$MapSearchStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$MapSearchStateErrorCopyWithImpl<$Res>
    implements $MapSearchStateErrorCopyWith<$Res> {
  _$MapSearchStateErrorCopyWithImpl(this._self, this._then);

  final MapSearchStateError _self;
  final $Res Function(MapSearchStateError) _then;

/// Create a copy of MapSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(MapSearchStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
