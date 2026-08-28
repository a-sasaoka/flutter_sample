// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_spot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MapSpot {

/// スポット ID
 String get id;/// スポット名称
 String get name;/// カテゴリ
 SpotCategory get category;/// 緯度
 double get latitude;/// 経度
 double get longitude;/// 住所
 String? get address;/// スポット説明
 String? get description;/// 評価 (0.0 - 5.0)
 double? get rating;
/// Create a copy of MapSpot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapSpotCopyWith<MapSpot> get copyWith => _$MapSpotCopyWithImpl<MapSpot>(this as MapSpot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapSpot&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.address, address) || other.address == address)&&(identical(other.description, description) || other.description == description)&&(identical(other.rating, rating) || other.rating == rating));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,category,latitude,longitude,address,description,rating);

@override
String toString() {
  return 'MapSpot(id: $id, name: $name, category: $category, latitude: $latitude, longitude: $longitude, address: $address, description: $description, rating: $rating)';
}


}

/// @nodoc
abstract mixin class $MapSpotCopyWith<$Res>  {
  factory $MapSpotCopyWith(MapSpot value, $Res Function(MapSpot) _then) = _$MapSpotCopyWithImpl;
@useResult
$Res call({
 String id, String name, SpotCategory category, double latitude, double longitude, String? address, String? description, double? rating
});




}
/// @nodoc
class _$MapSpotCopyWithImpl<$Res>
    implements $MapSpotCopyWith<$Res> {
  _$MapSpotCopyWithImpl(this._self, this._then);

  final MapSpot _self;
  final $Res Function(MapSpot) _then;

/// Create a copy of MapSpot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? category = null,Object? latitude = null,Object? longitude = null,Object? address = freezed,Object? description = freezed,Object? rating = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as SpotCategory,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [MapSpot].
extension MapSpotPatterns on MapSpot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapSpot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapSpot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapSpot value)  $default,){
final _that = this;
switch (_that) {
case _MapSpot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapSpot value)?  $default,){
final _that = this;
switch (_that) {
case _MapSpot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  SpotCategory category,  double latitude,  double longitude,  String? address,  String? description,  double? rating)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapSpot() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.latitude,_that.longitude,_that.address,_that.description,_that.rating);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  SpotCategory category,  double latitude,  double longitude,  String? address,  String? description,  double? rating)  $default,) {final _that = this;
switch (_that) {
case _MapSpot():
return $default(_that.id,_that.name,_that.category,_that.latitude,_that.longitude,_that.address,_that.description,_that.rating);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  SpotCategory category,  double latitude,  double longitude,  String? address,  String? description,  double? rating)?  $default,) {final _that = this;
switch (_that) {
case _MapSpot() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.latitude,_that.longitude,_that.address,_that.description,_that.rating);case _:
  return null;

}
}

}

/// @nodoc


class _MapSpot implements MapSpot {
  const _MapSpot({required this.id, required this.name, required this.category, required this.latitude, required this.longitude, this.address, this.description, this.rating});
  

/// スポット ID
@override final  String id;
/// スポット名称
@override final  String name;
/// カテゴリ
@override final  SpotCategory category;
/// 緯度
@override final  double latitude;
/// 経度
@override final  double longitude;
/// 住所
@override final  String? address;
/// スポット説明
@override final  String? description;
/// 評価 (0.0 - 5.0)
@override final  double? rating;

/// Create a copy of MapSpot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapSpotCopyWith<_MapSpot> get copyWith => __$MapSpotCopyWithImpl<_MapSpot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapSpot&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.address, address) || other.address == address)&&(identical(other.description, description) || other.description == description)&&(identical(other.rating, rating) || other.rating == rating));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,category,latitude,longitude,address,description,rating);

@override
String toString() {
  return 'MapSpot(id: $id, name: $name, category: $category, latitude: $latitude, longitude: $longitude, address: $address, description: $description, rating: $rating)';
}


}

/// @nodoc
abstract mixin class _$MapSpotCopyWith<$Res> implements $MapSpotCopyWith<$Res> {
  factory _$MapSpotCopyWith(_MapSpot value, $Res Function(_MapSpot) _then) = __$MapSpotCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, SpotCategory category, double latitude, double longitude, String? address, String? description, double? rating
});




}
/// @nodoc
class __$MapSpotCopyWithImpl<$Res>
    implements _$MapSpotCopyWith<$Res> {
  __$MapSpotCopyWithImpl(this._self, this._then);

  final _MapSpot _self;
  final $Res Function(_MapSpot) _then;

/// Create a copy of MapSpot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? category = null,Object? latitude = null,Object? longitude = null,Object? address = freezed,Object? description = freezed,Object? rating = freezed,}) {
  return _then(_MapSpot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as SpotCategory,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
