// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_candidate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocationCandidate {

 double get latitude; double get longitude; String get name; String? get address;
/// Create a copy of LocationCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationCandidateCopyWith<LocationCandidate> get copyWith => _$LocationCandidateCopyWithImpl<LocationCandidate>(this as LocationCandidate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationCandidate&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode => Object.hash(runtimeType,latitude,longitude,name,address);

@override
String toString() {
  return 'LocationCandidate(latitude: $latitude, longitude: $longitude, name: $name, address: $address)';
}


}

/// @nodoc
abstract mixin class $LocationCandidateCopyWith<$Res>  {
  factory $LocationCandidateCopyWith(LocationCandidate value, $Res Function(LocationCandidate) _then) = _$LocationCandidateCopyWithImpl;
@useResult
$Res call({
 double latitude, double longitude, String name, String? address
});




}
/// @nodoc
class _$LocationCandidateCopyWithImpl<$Res>
    implements $LocationCandidateCopyWith<$Res> {
  _$LocationCandidateCopyWithImpl(this._self, this._then);

  final LocationCandidate _self;
  final $Res Function(LocationCandidate) _then;

/// Create a copy of LocationCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? latitude = null,Object? longitude = null,Object? name = null,Object? address = freezed,}) {
  return _then(_self.copyWith(
latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LocationCandidate].
extension LocationCandidatePatterns on LocationCandidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocationCandidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocationCandidate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocationCandidate value)  $default,){
final _that = this;
switch (_that) {
case _LocationCandidate():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocationCandidate value)?  $default,){
final _that = this;
switch (_that) {
case _LocationCandidate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double latitude,  double longitude,  String name,  String? address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocationCandidate() when $default != null:
return $default(_that.latitude,_that.longitude,_that.name,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double latitude,  double longitude,  String name,  String? address)  $default,) {final _that = this;
switch (_that) {
case _LocationCandidate():
return $default(_that.latitude,_that.longitude,_that.name,_that.address);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double latitude,  double longitude,  String name,  String? address)?  $default,) {final _that = this;
switch (_that) {
case _LocationCandidate() when $default != null:
return $default(_that.latitude,_that.longitude,_that.name,_that.address);case _:
  return null;

}
}

}

/// @nodoc


class _LocationCandidate implements LocationCandidate {
  const _LocationCandidate({required this.latitude, required this.longitude, required this.name, this.address});
  

@override final  double latitude;
@override final  double longitude;
@override final  String name;
@override final  String? address;

/// Create a copy of LocationCandidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocationCandidateCopyWith<_LocationCandidate> get copyWith => __$LocationCandidateCopyWithImpl<_LocationCandidate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocationCandidate&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode => Object.hash(runtimeType,latitude,longitude,name,address);

@override
String toString() {
  return 'LocationCandidate(latitude: $latitude, longitude: $longitude, name: $name, address: $address)';
}


}

/// @nodoc
abstract mixin class _$LocationCandidateCopyWith<$Res> implements $LocationCandidateCopyWith<$Res> {
  factory _$LocationCandidateCopyWith(_LocationCandidate value, $Res Function(_LocationCandidate) _then) = __$LocationCandidateCopyWithImpl;
@override @useResult
$Res call({
 double latitude, double longitude, String name, String? address
});




}
/// @nodoc
class __$LocationCandidateCopyWithImpl<$Res>
    implements _$LocationCandidateCopyWith<$Res> {
  __$LocationCandidateCopyWithImpl(this._self, this._then);

  final _LocationCandidate _self;
  final $Res Function(_LocationCandidate) _then;

/// Create a copy of LocationCandidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? latitude = null,Object? longitude = null,Object? name = null,Object? address = freezed,}) {
  return _then(_LocationCandidate(
latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
