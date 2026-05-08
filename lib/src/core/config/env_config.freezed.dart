// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'env_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EnvConfigState {

/// API ベース URL
 String get baseUrl;/// AI モデル名
 String get aiModel;/// 接続タイムアウト（秒）
 int get connectTimeout;/// 受信タイムアウト（秒）
 int get receiveTimeout;/// 送信タイムアウト（秒）
 int get sendTimeout;/// Firebase Auth を使用するかどうか
 bool get useFirebaseAuth;
/// Create a copy of EnvConfigState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnvConfigStateCopyWith<EnvConfigState> get copyWith => _$EnvConfigStateCopyWithImpl<EnvConfigState>(this as EnvConfigState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnvConfigState&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.aiModel, aiModel) || other.aiModel == aiModel)&&(identical(other.connectTimeout, connectTimeout) || other.connectTimeout == connectTimeout)&&(identical(other.receiveTimeout, receiveTimeout) || other.receiveTimeout == receiveTimeout)&&(identical(other.sendTimeout, sendTimeout) || other.sendTimeout == sendTimeout)&&(identical(other.useFirebaseAuth, useFirebaseAuth) || other.useFirebaseAuth == useFirebaseAuth));
}


@override
int get hashCode => Object.hash(runtimeType,baseUrl,aiModel,connectTimeout,receiveTimeout,sendTimeout,useFirebaseAuth);

@override
String toString() {
  return 'EnvConfigState(baseUrl: $baseUrl, aiModel: $aiModel, connectTimeout: $connectTimeout, receiveTimeout: $receiveTimeout, sendTimeout: $sendTimeout, useFirebaseAuth: $useFirebaseAuth)';
}


}

/// @nodoc
abstract mixin class $EnvConfigStateCopyWith<$Res>  {
  factory $EnvConfigStateCopyWith(EnvConfigState value, $Res Function(EnvConfigState) _then) = _$EnvConfigStateCopyWithImpl;
@useResult
$Res call({
 String baseUrl, String aiModel, int connectTimeout, int receiveTimeout, int sendTimeout, bool useFirebaseAuth
});




}
/// @nodoc
class _$EnvConfigStateCopyWithImpl<$Res>
    implements $EnvConfigStateCopyWith<$Res> {
  _$EnvConfigStateCopyWithImpl(this._self, this._then);

  final EnvConfigState _self;
  final $Res Function(EnvConfigState) _then;

/// Create a copy of EnvConfigState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? baseUrl = null,Object? aiModel = null,Object? connectTimeout = null,Object? receiveTimeout = null,Object? sendTimeout = null,Object? useFirebaseAuth = null,}) {
  return _then(_self.copyWith(
baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,aiModel: null == aiModel ? _self.aiModel : aiModel // ignore: cast_nullable_to_non_nullable
as String,connectTimeout: null == connectTimeout ? _self.connectTimeout : connectTimeout // ignore: cast_nullable_to_non_nullable
as int,receiveTimeout: null == receiveTimeout ? _self.receiveTimeout : receiveTimeout // ignore: cast_nullable_to_non_nullable
as int,sendTimeout: null == sendTimeout ? _self.sendTimeout : sendTimeout // ignore: cast_nullable_to_non_nullable
as int,useFirebaseAuth: null == useFirebaseAuth ? _self.useFirebaseAuth : useFirebaseAuth // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [EnvConfigState].
extension EnvConfigStatePatterns on EnvConfigState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnvConfigState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnvConfigState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnvConfigState value)  $default,){
final _that = this;
switch (_that) {
case _EnvConfigState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnvConfigState value)?  $default,){
final _that = this;
switch (_that) {
case _EnvConfigState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String baseUrl,  String aiModel,  int connectTimeout,  int receiveTimeout,  int sendTimeout,  bool useFirebaseAuth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnvConfigState() when $default != null:
return $default(_that.baseUrl,_that.aiModel,_that.connectTimeout,_that.receiveTimeout,_that.sendTimeout,_that.useFirebaseAuth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String baseUrl,  String aiModel,  int connectTimeout,  int receiveTimeout,  int sendTimeout,  bool useFirebaseAuth)  $default,) {final _that = this;
switch (_that) {
case _EnvConfigState():
return $default(_that.baseUrl,_that.aiModel,_that.connectTimeout,_that.receiveTimeout,_that.sendTimeout,_that.useFirebaseAuth);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String baseUrl,  String aiModel,  int connectTimeout,  int receiveTimeout,  int sendTimeout,  bool useFirebaseAuth)?  $default,) {final _that = this;
switch (_that) {
case _EnvConfigState() when $default != null:
return $default(_that.baseUrl,_that.aiModel,_that.connectTimeout,_that.receiveTimeout,_that.sendTimeout,_that.useFirebaseAuth);case _:
  return null;

}
}

}

/// @nodoc


class _EnvConfigState extends EnvConfigState {
  const _EnvConfigState({required this.baseUrl, required this.aiModel, required this.connectTimeout, required this.receiveTimeout, required this.sendTimeout, required this.useFirebaseAuth}): super._();
  

/// API ベース URL
@override final  String baseUrl;
/// AI モデル名
@override final  String aiModel;
/// 接続タイムアウト（秒）
@override final  int connectTimeout;
/// 受信タイムアウト（秒）
@override final  int receiveTimeout;
/// 送信タイムアウト（秒）
@override final  int sendTimeout;
/// Firebase Auth を使用するかどうか
@override final  bool useFirebaseAuth;

/// Create a copy of EnvConfigState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnvConfigStateCopyWith<_EnvConfigState> get copyWith => __$EnvConfigStateCopyWithImpl<_EnvConfigState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnvConfigState&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.aiModel, aiModel) || other.aiModel == aiModel)&&(identical(other.connectTimeout, connectTimeout) || other.connectTimeout == connectTimeout)&&(identical(other.receiveTimeout, receiveTimeout) || other.receiveTimeout == receiveTimeout)&&(identical(other.sendTimeout, sendTimeout) || other.sendTimeout == sendTimeout)&&(identical(other.useFirebaseAuth, useFirebaseAuth) || other.useFirebaseAuth == useFirebaseAuth));
}


@override
int get hashCode => Object.hash(runtimeType,baseUrl,aiModel,connectTimeout,receiveTimeout,sendTimeout,useFirebaseAuth);

@override
String toString() {
  return 'EnvConfigState(baseUrl: $baseUrl, aiModel: $aiModel, connectTimeout: $connectTimeout, receiveTimeout: $receiveTimeout, sendTimeout: $sendTimeout, useFirebaseAuth: $useFirebaseAuth)';
}


}

/// @nodoc
abstract mixin class _$EnvConfigStateCopyWith<$Res> implements $EnvConfigStateCopyWith<$Res> {
  factory _$EnvConfigStateCopyWith(_EnvConfigState value, $Res Function(_EnvConfigState) _then) = __$EnvConfigStateCopyWithImpl;
@override @useResult
$Res call({
 String baseUrl, String aiModel, int connectTimeout, int receiveTimeout, int sendTimeout, bool useFirebaseAuth
});




}
/// @nodoc
class __$EnvConfigStateCopyWithImpl<$Res>
    implements _$EnvConfigStateCopyWith<$Res> {
  __$EnvConfigStateCopyWithImpl(this._self, this._then);

  final _EnvConfigState _self;
  final $Res Function(_EnvConfigState) _then;

/// Create a copy of EnvConfigState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? baseUrl = null,Object? aiModel = null,Object? connectTimeout = null,Object? receiveTimeout = null,Object? sendTimeout = null,Object? useFirebaseAuth = null,}) {
  return _then(_EnvConfigState(
baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,aiModel: null == aiModel ? _self.aiModel : aiModel // ignore: cast_nullable_to_non_nullable
as String,connectTimeout: null == connectTimeout ? _self.connectTimeout : connectTimeout // ignore: cast_nullable_to_non_nullable
as int,receiveTimeout: null == receiveTimeout ? _self.receiveTimeout : receiveTimeout // ignore: cast_nullable_to_non_nullable
as int,sendTimeout: null == sendTimeout ? _self.sendTimeout : sendTimeout // ignore: cast_nullable_to_non_nullable
as int,useFirebaseAuth: null == useFirebaseAuth ? _self.useFirebaseAuth : useFirebaseAuth // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
