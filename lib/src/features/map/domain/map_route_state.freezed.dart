// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_route_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MapRouteState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapRouteState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MapRouteState()';
}


}

/// @nodoc
class $MapRouteStateCopyWith<$Res>  {
$MapRouteStateCopyWith(MapRouteState _, $Res Function(MapRouteState) __);
}


/// Adds pattern-matching-related methods to [MapRouteState].
extension MapRouteStatePatterns on MapRouteState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MapRouteStateInitial value)?  initial,TResult Function( MapRouteStateLoading value)?  loading,TResult Function( MapRouteStateSuccess value)?  success,TResult Function( MapRouteStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MapRouteStateInitial() when initial != null:
return initial(_that);case MapRouteStateLoading() when loading != null:
return loading(_that);case MapRouteStateSuccess() when success != null:
return success(_that);case MapRouteStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MapRouteStateInitial value)  initial,required TResult Function( MapRouteStateLoading value)  loading,required TResult Function( MapRouteStateSuccess value)  success,required TResult Function( MapRouteStateError value)  error,}){
final _that = this;
switch (_that) {
case MapRouteStateInitial():
return initial(_that);case MapRouteStateLoading():
return loading(_that);case MapRouteStateSuccess():
return success(_that);case MapRouteStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MapRouteStateInitial value)?  initial,TResult? Function( MapRouteStateLoading value)?  loading,TResult? Function( MapRouteStateSuccess value)?  success,TResult? Function( MapRouteStateError value)?  error,}){
final _that = this;
switch (_that) {
case MapRouteStateInitial() when initial != null:
return initial(_that);case MapRouteStateLoading() when loading != null:
return loading(_that);case MapRouteStateSuccess() when success != null:
return success(_that);case MapRouteStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( MapRoute route)?  success,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MapRouteStateInitial() when initial != null:
return initial();case MapRouteStateLoading() when loading != null:
return loading();case MapRouteStateSuccess() when success != null:
return success(_that.route);case MapRouteStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( MapRoute route)  success,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case MapRouteStateInitial():
return initial();case MapRouteStateLoading():
return loading();case MapRouteStateSuccess():
return success(_that.route);case MapRouteStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( MapRoute route)?  success,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case MapRouteStateInitial() when initial != null:
return initial();case MapRouteStateLoading() when loading != null:
return loading();case MapRouteStateSuccess() when success != null:
return success(_that.route);case MapRouteStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class MapRouteStateInitial implements MapRouteState {
  const MapRouteStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapRouteStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MapRouteState.initial()';
}


}




/// @nodoc


class MapRouteStateLoading implements MapRouteState {
  const MapRouteStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapRouteStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MapRouteState.loading()';
}


}




/// @nodoc


class MapRouteStateSuccess implements MapRouteState {
  const MapRouteStateSuccess(this.route);
  

 final  MapRoute route;

/// Create a copy of MapRouteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapRouteStateSuccessCopyWith<MapRouteStateSuccess> get copyWith => _$MapRouteStateSuccessCopyWithImpl<MapRouteStateSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapRouteStateSuccess&&(identical(other.route, route) || other.route == route));
}


@override
int get hashCode => Object.hash(runtimeType,route);

@override
String toString() {
  return 'MapRouteState.success(route: $route)';
}


}

/// @nodoc
abstract mixin class $MapRouteStateSuccessCopyWith<$Res> implements $MapRouteStateCopyWith<$Res> {
  factory $MapRouteStateSuccessCopyWith(MapRouteStateSuccess value, $Res Function(MapRouteStateSuccess) _then) = _$MapRouteStateSuccessCopyWithImpl;
@useResult
$Res call({
 MapRoute route
});


$MapRouteCopyWith<$Res> get route;

}
/// @nodoc
class _$MapRouteStateSuccessCopyWithImpl<$Res>
    implements $MapRouteStateSuccessCopyWith<$Res> {
  _$MapRouteStateSuccessCopyWithImpl(this._self, this._then);

  final MapRouteStateSuccess _self;
  final $Res Function(MapRouteStateSuccess) _then;

/// Create a copy of MapRouteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? route = null,}) {
  return _then(MapRouteStateSuccess(
null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as MapRoute,
  ));
}

/// Create a copy of MapRouteState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapRouteCopyWith<$Res> get route {
  
  return $MapRouteCopyWith<$Res>(_self.route, (value) {
    return _then(_self.copyWith(route: value));
  });
}
}

/// @nodoc


class MapRouteStateError implements MapRouteState {
  const MapRouteStateError(this.message);
  

 final  String message;

/// Create a copy of MapRouteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapRouteStateErrorCopyWith<MapRouteStateError> get copyWith => _$MapRouteStateErrorCopyWithImpl<MapRouteStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapRouteStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'MapRouteState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $MapRouteStateErrorCopyWith<$Res> implements $MapRouteStateCopyWith<$Res> {
  factory $MapRouteStateErrorCopyWith(MapRouteStateError value, $Res Function(MapRouteStateError) _then) = _$MapRouteStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$MapRouteStateErrorCopyWithImpl<$Res>
    implements $MapRouteStateErrorCopyWith<$Res> {
  _$MapRouteStateErrorCopyWithImpl(this._self, this._then);

  final MapRouteStateError _self;
  final $Res Function(MapRouteStateError) _then;

/// Create a copy of MapRouteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(MapRouteStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
