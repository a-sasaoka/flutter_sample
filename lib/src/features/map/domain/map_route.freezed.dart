// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_route.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MapRoute {

/// ルートの固有ID
 String get id;/// 出発地座標
 LatLng get origin;/// 目的地座標
 LatLng get destination;/// 経路を構成する緯度経度座標リスト (Polyline用)
 List<LatLng> get points;/// 総移動距離 (メートル単位)
 double get distanceMeters;/// 総予想所要時間 (秒単位)
 int get durationSeconds;/// 目的地の名称 (スポット名や住所など)
 String? get destinationName;/// 移動手段の種別 (車、徒歩、自転車、公共交通機関)
 TravelMode get travelMode;
/// Create a copy of MapRoute
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapRouteCopyWith<MapRoute> get copyWith => _$MapRouteCopyWithImpl<MapRoute>(this as MapRoute, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapRoute&&(identical(other.id, id) || other.id == id)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.destination, destination) || other.destination == destination)&&const DeepCollectionEquality().equals(other.points, points)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.destinationName, destinationName) || other.destinationName == destinationName)&&(identical(other.travelMode, travelMode) || other.travelMode == travelMode));
}


@override
int get hashCode => Object.hash(runtimeType,id,origin,destination,const DeepCollectionEquality().hash(points),distanceMeters,durationSeconds,destinationName,travelMode);

@override
String toString() {
  return 'MapRoute(id: $id, origin: $origin, destination: $destination, points: $points, distanceMeters: $distanceMeters, durationSeconds: $durationSeconds, destinationName: $destinationName, travelMode: $travelMode)';
}


}

/// @nodoc
abstract mixin class $MapRouteCopyWith<$Res>  {
  factory $MapRouteCopyWith(MapRoute value, $Res Function(MapRoute) _then) = _$MapRouteCopyWithImpl;
@useResult
$Res call({
 String id, LatLng origin, LatLng destination, List<LatLng> points, double distanceMeters, int durationSeconds, String? destinationName, TravelMode travelMode
});




}
/// @nodoc
class _$MapRouteCopyWithImpl<$Res>
    implements $MapRouteCopyWith<$Res> {
  _$MapRouteCopyWithImpl(this._self, this._then);

  final MapRoute _self;
  final $Res Function(MapRoute) _then;

/// Create a copy of MapRoute
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? origin = null,Object? destination = null,Object? points = null,Object? distanceMeters = null,Object? durationSeconds = null,Object? destinationName = freezed,Object? travelMode = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as LatLng,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as LatLng,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<LatLng>,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,destinationName: freezed == destinationName ? _self.destinationName : destinationName // ignore: cast_nullable_to_non_nullable
as String?,travelMode: null == travelMode ? _self.travelMode : travelMode // ignore: cast_nullable_to_non_nullable
as TravelMode,
  ));
}

}


/// Adds pattern-matching-related methods to [MapRoute].
extension MapRoutePatterns on MapRoute {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapRoute value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapRoute() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapRoute value)  $default,){
final _that = this;
switch (_that) {
case _MapRoute():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapRoute value)?  $default,){
final _that = this;
switch (_that) {
case _MapRoute() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  LatLng origin,  LatLng destination,  List<LatLng> points,  double distanceMeters,  int durationSeconds,  String? destinationName,  TravelMode travelMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapRoute() when $default != null:
return $default(_that.id,_that.origin,_that.destination,_that.points,_that.distanceMeters,_that.durationSeconds,_that.destinationName,_that.travelMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  LatLng origin,  LatLng destination,  List<LatLng> points,  double distanceMeters,  int durationSeconds,  String? destinationName,  TravelMode travelMode)  $default,) {final _that = this;
switch (_that) {
case _MapRoute():
return $default(_that.id,_that.origin,_that.destination,_that.points,_that.distanceMeters,_that.durationSeconds,_that.destinationName,_that.travelMode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  LatLng origin,  LatLng destination,  List<LatLng> points,  double distanceMeters,  int durationSeconds,  String? destinationName,  TravelMode travelMode)?  $default,) {final _that = this;
switch (_that) {
case _MapRoute() when $default != null:
return $default(_that.id,_that.origin,_that.destination,_that.points,_that.distanceMeters,_that.durationSeconds,_that.destinationName,_that.travelMode);case _:
  return null;

}
}

}

/// @nodoc


class _MapRoute extends MapRoute {
  const _MapRoute({required this.id, required this.origin, required this.destination, required final  List<LatLng> points, required this.distanceMeters, required this.durationSeconds, this.destinationName, this.travelMode = TravelMode.driving}): _points = points,super._();
  

/// ルートの固有ID
@override final  String id;
/// 出発地座標
@override final  LatLng origin;
/// 目的地座標
@override final  LatLng destination;
/// 経路を構成する緯度経度座標リスト (Polyline用)
 final  List<LatLng> _points;
/// 経路を構成する緯度経度座標リスト (Polyline用)
@override List<LatLng> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}

/// 総移動距離 (メートル単位)
@override final  double distanceMeters;
/// 総予想所要時間 (秒単位)
@override final  int durationSeconds;
/// 目的地の名称 (スポット名や住所など)
@override final  String? destinationName;
/// 移動手段の種別 (車、徒歩、自転車、公共交通機関)
@override@JsonKey() final  TravelMode travelMode;

/// Create a copy of MapRoute
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapRouteCopyWith<_MapRoute> get copyWith => __$MapRouteCopyWithImpl<_MapRoute>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapRoute&&(identical(other.id, id) || other.id == id)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.destination, destination) || other.destination == destination)&&const DeepCollectionEquality().equals(other._points, _points)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.destinationName, destinationName) || other.destinationName == destinationName)&&(identical(other.travelMode, travelMode) || other.travelMode == travelMode));
}


@override
int get hashCode => Object.hash(runtimeType,id,origin,destination,const DeepCollectionEquality().hash(_points),distanceMeters,durationSeconds,destinationName,travelMode);

@override
String toString() {
  return 'MapRoute(id: $id, origin: $origin, destination: $destination, points: $points, distanceMeters: $distanceMeters, durationSeconds: $durationSeconds, destinationName: $destinationName, travelMode: $travelMode)';
}


}

/// @nodoc
abstract mixin class _$MapRouteCopyWith<$Res> implements $MapRouteCopyWith<$Res> {
  factory _$MapRouteCopyWith(_MapRoute value, $Res Function(_MapRoute) _then) = __$MapRouteCopyWithImpl;
@override @useResult
$Res call({
 String id, LatLng origin, LatLng destination, List<LatLng> points, double distanceMeters, int durationSeconds, String? destinationName, TravelMode travelMode
});




}
/// @nodoc
class __$MapRouteCopyWithImpl<$Res>
    implements _$MapRouteCopyWith<$Res> {
  __$MapRouteCopyWithImpl(this._self, this._then);

  final _MapRoute _self;
  final $Res Function(_MapRoute) _then;

/// Create a copy of MapRoute
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? origin = null,Object? destination = null,Object? points = null,Object? distanceMeters = null,Object? durationSeconds = null,Object? destinationName = freezed,Object? travelMode = null,}) {
  return _then(_MapRoute(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as LatLng,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as LatLng,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<LatLng>,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,destinationName: freezed == destinationName ? _self.destinationName : destinationName // ignore: cast_nullable_to_non_nullable
as String?,travelMode: null == travelMode ? _self.travelMode : travelMode // ignore: cast_nullable_to_non_nullable
as TravelMode,
  ));
}


}

// dart format on
