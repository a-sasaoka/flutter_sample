// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocationState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocationState()';
}


}

/// @nodoc
class $LocationStateCopyWith<$Res>  {
$LocationStateCopyWith(LocationState _, $Res Function(LocationState) __);
}


/// Adds pattern-matching-related methods to [LocationState].
extension LocationStatePatterns on LocationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LocationStateInitial value)?  initial,TResult Function( LocationStateLoading value)?  loading,TResult Function( LocationStateSuccess value)?  success,TResult Function( LocationStatePermissionDenied value)?  permissionDenied,TResult Function( LocationStatePermissionDeniedForever value)?  permissionDeniedForever,TResult Function( LocationStateServiceDisabled value)?  serviceDisabled,TResult Function( LocationStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LocationStateInitial() when initial != null:
return initial(_that);case LocationStateLoading() when loading != null:
return loading(_that);case LocationStateSuccess() when success != null:
return success(_that);case LocationStatePermissionDenied() when permissionDenied != null:
return permissionDenied(_that);case LocationStatePermissionDeniedForever() when permissionDeniedForever != null:
return permissionDeniedForever(_that);case LocationStateServiceDisabled() when serviceDisabled != null:
return serviceDisabled(_that);case LocationStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LocationStateInitial value)  initial,required TResult Function( LocationStateLoading value)  loading,required TResult Function( LocationStateSuccess value)  success,required TResult Function( LocationStatePermissionDenied value)  permissionDenied,required TResult Function( LocationStatePermissionDeniedForever value)  permissionDeniedForever,required TResult Function( LocationStateServiceDisabled value)  serviceDisabled,required TResult Function( LocationStateError value)  error,}){
final _that = this;
switch (_that) {
case LocationStateInitial():
return initial(_that);case LocationStateLoading():
return loading(_that);case LocationStateSuccess():
return success(_that);case LocationStatePermissionDenied():
return permissionDenied(_that);case LocationStatePermissionDeniedForever():
return permissionDeniedForever(_that);case LocationStateServiceDisabled():
return serviceDisabled(_that);case LocationStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LocationStateInitial value)?  initial,TResult? Function( LocationStateLoading value)?  loading,TResult? Function( LocationStateSuccess value)?  success,TResult? Function( LocationStatePermissionDenied value)?  permissionDenied,TResult? Function( LocationStatePermissionDeniedForever value)?  permissionDeniedForever,TResult? Function( LocationStateServiceDisabled value)?  serviceDisabled,TResult? Function( LocationStateError value)?  error,}){
final _that = this;
switch (_that) {
case LocationStateInitial() when initial != null:
return initial(_that);case LocationStateLoading() when loading != null:
return loading(_that);case LocationStateSuccess() when success != null:
return success(_that);case LocationStatePermissionDenied() when permissionDenied != null:
return permissionDenied(_that);case LocationStatePermissionDeniedForever() when permissionDeniedForever != null:
return permissionDeniedForever(_that);case LocationStateServiceDisabled() when serviceDisabled != null:
return serviceDisabled(_that);case LocationStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( Position position)?  success,TResult Function()?  permissionDenied,TResult Function()?  permissionDeniedForever,TResult Function()?  serviceDisabled,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LocationStateInitial() when initial != null:
return initial();case LocationStateLoading() when loading != null:
return loading();case LocationStateSuccess() when success != null:
return success(_that.position);case LocationStatePermissionDenied() when permissionDenied != null:
return permissionDenied();case LocationStatePermissionDeniedForever() when permissionDeniedForever != null:
return permissionDeniedForever();case LocationStateServiceDisabled() when serviceDisabled != null:
return serviceDisabled();case LocationStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( Position position)  success,required TResult Function()  permissionDenied,required TResult Function()  permissionDeniedForever,required TResult Function()  serviceDisabled,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case LocationStateInitial():
return initial();case LocationStateLoading():
return loading();case LocationStateSuccess():
return success(_that.position);case LocationStatePermissionDenied():
return permissionDenied();case LocationStatePermissionDeniedForever():
return permissionDeniedForever();case LocationStateServiceDisabled():
return serviceDisabled();case LocationStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( Position position)?  success,TResult? Function()?  permissionDenied,TResult? Function()?  permissionDeniedForever,TResult? Function()?  serviceDisabled,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case LocationStateInitial() when initial != null:
return initial();case LocationStateLoading() when loading != null:
return loading();case LocationStateSuccess() when success != null:
return success(_that.position);case LocationStatePermissionDenied() when permissionDenied != null:
return permissionDenied();case LocationStatePermissionDeniedForever() when permissionDeniedForever != null:
return permissionDeniedForever();case LocationStateServiceDisabled() when serviceDisabled != null:
return serviceDisabled();case LocationStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class LocationStateInitial implements LocationState {
  const LocationStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocationState.initial()';
}


}




/// @nodoc


class LocationStateLoading implements LocationState {
  const LocationStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocationState.loading()';
}


}




/// @nodoc


class LocationStateSuccess implements LocationState {
  const LocationStateSuccess(this.position);
  

 final  Position position;

/// Create a copy of LocationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationStateSuccessCopyWith<LocationStateSuccess> get copyWith => _$LocationStateSuccessCopyWithImpl<LocationStateSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationStateSuccess&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode => Object.hash(runtimeType,position);

@override
String toString() {
  return 'LocationState.success(position: $position)';
}


}

/// @nodoc
abstract mixin class $LocationStateSuccessCopyWith<$Res> implements $LocationStateCopyWith<$Res> {
  factory $LocationStateSuccessCopyWith(LocationStateSuccess value, $Res Function(LocationStateSuccess) _then) = _$LocationStateSuccessCopyWithImpl;
@useResult
$Res call({
 Position position
});




}
/// @nodoc
class _$LocationStateSuccessCopyWithImpl<$Res>
    implements $LocationStateSuccessCopyWith<$Res> {
  _$LocationStateSuccessCopyWithImpl(this._self, this._then);

  final LocationStateSuccess _self;
  final $Res Function(LocationStateSuccess) _then;

/// Create a copy of LocationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? position = null,}) {
  return _then(LocationStateSuccess(
null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Position,
  ));
}


}

/// @nodoc


class LocationStatePermissionDenied implements LocationState {
  const LocationStatePermissionDenied();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationStatePermissionDenied);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocationState.permissionDenied()';
}


}




/// @nodoc


class LocationStatePermissionDeniedForever implements LocationState {
  const LocationStatePermissionDeniedForever();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationStatePermissionDeniedForever);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocationState.permissionDeniedForever()';
}


}




/// @nodoc


class LocationStateServiceDisabled implements LocationState {
  const LocationStateServiceDisabled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationStateServiceDisabled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocationState.serviceDisabled()';
}


}




/// @nodoc


class LocationStateError implements LocationState {
  const LocationStateError(this.message);
  

 final  String message;

/// Create a copy of LocationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationStateErrorCopyWith<LocationStateError> get copyWith => _$LocationStateErrorCopyWithImpl<LocationStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'LocationState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $LocationStateErrorCopyWith<$Res> implements $LocationStateCopyWith<$Res> {
  factory $LocationStateErrorCopyWith(LocationStateError value, $Res Function(LocationStateError) _then) = _$LocationStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$LocationStateErrorCopyWithImpl<$Res>
    implements $LocationStateErrorCopyWith<$Res> {
  _$LocationStateErrorCopyWithImpl(this._self, this._then);

  final LocationStateError _self;
  final $Res Function(LocationStateError) _then;

/// Create a copy of LocationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(LocationStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
