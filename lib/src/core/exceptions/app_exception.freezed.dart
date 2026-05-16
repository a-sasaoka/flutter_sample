// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_exception.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppException {

 String? get message;
/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppExceptionCopyWith<AppException> get copyWith => _$AppExceptionCopyWithImpl<AppException>(this as AppException, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppException(message: $message)';
}


}

/// @nodoc
abstract mixin class $AppExceptionCopyWith<$Res>  {
  factory $AppExceptionCopyWith(AppException value, $Res Function(AppException) _then) = _$AppExceptionCopyWithImpl;
@useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$AppExceptionCopyWithImpl<$Res>
    implements $AppExceptionCopyWith<$Res> {
  _$AppExceptionCopyWithImpl(this._self, this._then);

  final AppException _self;
  final $Res Function(AppException) _then;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = freezed,}) {
  return _then(_self.copyWith(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppException].
extension AppExceptionPatterns on AppException {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NetworkException value)?  network,TResult Function( ServerException value)?  server,TResult Function( BadRequestException value)?  badRequest,TResult Function( UnauthenticatedException value)?  unauthenticated,TResult Function( UnauthorizedException value)?  unauthorized,TResult Function( TimeoutException value)?  timeout,TResult Function( DataParseException value)?  dataParse,TResult Function( DatabaseException value)?  database,TResult Function( CancelException value)?  cancel,TResult Function( UnknownException value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NetworkException() when network != null:
return network(_that);case ServerException() when server != null:
return server(_that);case BadRequestException() when badRequest != null:
return badRequest(_that);case UnauthenticatedException() when unauthenticated != null:
return unauthenticated(_that);case UnauthorizedException() when unauthorized != null:
return unauthorized(_that);case TimeoutException() when timeout != null:
return timeout(_that);case DataParseException() when dataParse != null:
return dataParse(_that);case DatabaseException() when database != null:
return database(_that);case CancelException() when cancel != null:
return cancel(_that);case UnknownException() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NetworkException value)  network,required TResult Function( ServerException value)  server,required TResult Function( BadRequestException value)  badRequest,required TResult Function( UnauthenticatedException value)  unauthenticated,required TResult Function( UnauthorizedException value)  unauthorized,required TResult Function( TimeoutException value)  timeout,required TResult Function( DataParseException value)  dataParse,required TResult Function( DatabaseException value)  database,required TResult Function( CancelException value)  cancel,required TResult Function( UnknownException value)  unknown,}){
final _that = this;
switch (_that) {
case NetworkException():
return network(_that);case ServerException():
return server(_that);case BadRequestException():
return badRequest(_that);case UnauthenticatedException():
return unauthenticated(_that);case UnauthorizedException():
return unauthorized(_that);case TimeoutException():
return timeout(_that);case DataParseException():
return dataParse(_that);case DatabaseException():
return database(_that);case CancelException():
return cancel(_that);case UnknownException():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NetworkException value)?  network,TResult? Function( ServerException value)?  server,TResult? Function( BadRequestException value)?  badRequest,TResult? Function( UnauthenticatedException value)?  unauthenticated,TResult? Function( UnauthorizedException value)?  unauthorized,TResult? Function( TimeoutException value)?  timeout,TResult? Function( DataParseException value)?  dataParse,TResult? Function( DatabaseException value)?  database,TResult? Function( CancelException value)?  cancel,TResult? Function( UnknownException value)?  unknown,}){
final _that = this;
switch (_that) {
case NetworkException() when network != null:
return network(_that);case ServerException() when server != null:
return server(_that);case BadRequestException() when badRequest != null:
return badRequest(_that);case UnauthenticatedException() when unauthenticated != null:
return unauthenticated(_that);case UnauthorizedException() when unauthorized != null:
return unauthorized(_that);case TimeoutException() when timeout != null:
return timeout(_that);case DataParseException() when dataParse != null:
return dataParse(_that);case DatabaseException() when database != null:
return database(_that);case CancelException() when cancel != null:
return cancel(_that);case UnknownException() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? message)?  network,TResult Function( int? statusCode,  String? message)?  server,TResult Function( int? statusCode,  String? message)?  badRequest,TResult Function( String? message)?  unauthenticated,TResult Function( String? message)?  unauthorized,TResult Function( String? message)?  timeout,TResult Function( String? message)?  dataParse,TResult Function( String? message,  Object? error)?  database,TResult Function( String? message)?  cancel,TResult Function( String? message,  Object? error)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NetworkException() when network != null:
return network(_that.message);case ServerException() when server != null:
return server(_that.statusCode,_that.message);case BadRequestException() when badRequest != null:
return badRequest(_that.statusCode,_that.message);case UnauthenticatedException() when unauthenticated != null:
return unauthenticated(_that.message);case UnauthorizedException() when unauthorized != null:
return unauthorized(_that.message);case TimeoutException() when timeout != null:
return timeout(_that.message);case DataParseException() when dataParse != null:
return dataParse(_that.message);case DatabaseException() when database != null:
return database(_that.message,_that.error);case CancelException() when cancel != null:
return cancel(_that.message);case UnknownException() when unknown != null:
return unknown(_that.message,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? message)  network,required TResult Function( int? statusCode,  String? message)  server,required TResult Function( int? statusCode,  String? message)  badRequest,required TResult Function( String? message)  unauthenticated,required TResult Function( String? message)  unauthorized,required TResult Function( String? message)  timeout,required TResult Function( String? message)  dataParse,required TResult Function( String? message,  Object? error)  database,required TResult Function( String? message)  cancel,required TResult Function( String? message,  Object? error)  unknown,}) {final _that = this;
switch (_that) {
case NetworkException():
return network(_that.message);case ServerException():
return server(_that.statusCode,_that.message);case BadRequestException():
return badRequest(_that.statusCode,_that.message);case UnauthenticatedException():
return unauthenticated(_that.message);case UnauthorizedException():
return unauthorized(_that.message);case TimeoutException():
return timeout(_that.message);case DataParseException():
return dataParse(_that.message);case DatabaseException():
return database(_that.message,_that.error);case CancelException():
return cancel(_that.message);case UnknownException():
return unknown(_that.message,_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? message)?  network,TResult? Function( int? statusCode,  String? message)?  server,TResult? Function( int? statusCode,  String? message)?  badRequest,TResult? Function( String? message)?  unauthenticated,TResult? Function( String? message)?  unauthorized,TResult? Function( String? message)?  timeout,TResult? Function( String? message)?  dataParse,TResult? Function( String? message,  Object? error)?  database,TResult? Function( String? message)?  cancel,TResult? Function( String? message,  Object? error)?  unknown,}) {final _that = this;
switch (_that) {
case NetworkException() when network != null:
return network(_that.message);case ServerException() when server != null:
return server(_that.statusCode,_that.message);case BadRequestException() when badRequest != null:
return badRequest(_that.statusCode,_that.message);case UnauthenticatedException() when unauthenticated != null:
return unauthenticated(_that.message);case UnauthorizedException() when unauthorized != null:
return unauthorized(_that.message);case TimeoutException() when timeout != null:
return timeout(_that.message);case DataParseException() when dataParse != null:
return dataParse(_that.message);case DatabaseException() when database != null:
return database(_that.message,_that.error);case CancelException() when cancel != null:
return cancel(_that.message);case UnknownException() when unknown != null:
return unknown(_that.message,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class NetworkException implements AppException {
  const NetworkException({this.message});
  

@override final  String? message;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkExceptionCopyWith<NetworkException> get copyWith => _$NetworkExceptionCopyWithImpl<NetworkException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppException.network(message: $message)';
}


}

/// @nodoc
abstract mixin class $NetworkExceptionCopyWith<$Res> implements $AppExceptionCopyWith<$Res> {
  factory $NetworkExceptionCopyWith(NetworkException value, $Res Function(NetworkException) _then) = _$NetworkExceptionCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$NetworkExceptionCopyWithImpl<$Res>
    implements $NetworkExceptionCopyWith<$Res> {
  _$NetworkExceptionCopyWithImpl(this._self, this._then);

  final NetworkException _self;
  final $Res Function(NetworkException) _then;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(NetworkException(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ServerException implements AppException {
  const ServerException({this.statusCode, this.message});
  

 final  int? statusCode;
@override final  String? message;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerExceptionCopyWith<ServerException> get copyWith => _$ServerExceptionCopyWithImpl<ServerException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerException&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,statusCode,message);

@override
String toString() {
  return 'AppException.server(statusCode: $statusCode, message: $message)';
}


}

/// @nodoc
abstract mixin class $ServerExceptionCopyWith<$Res> implements $AppExceptionCopyWith<$Res> {
  factory $ServerExceptionCopyWith(ServerException value, $Res Function(ServerException) _then) = _$ServerExceptionCopyWithImpl;
@override @useResult
$Res call({
 int? statusCode, String? message
});




}
/// @nodoc
class _$ServerExceptionCopyWithImpl<$Res>
    implements $ServerExceptionCopyWith<$Res> {
  _$ServerExceptionCopyWithImpl(this._self, this._then);

  final ServerException _self;
  final $Res Function(ServerException) _then;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? statusCode = freezed,Object? message = freezed,}) {
  return _then(ServerException(
statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class BadRequestException implements AppException {
  const BadRequestException({this.statusCode, this.message});
  

 final  int? statusCode;
@override final  String? message;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BadRequestExceptionCopyWith<BadRequestException> get copyWith => _$BadRequestExceptionCopyWithImpl<BadRequestException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BadRequestException&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,statusCode,message);

@override
String toString() {
  return 'AppException.badRequest(statusCode: $statusCode, message: $message)';
}


}

/// @nodoc
abstract mixin class $BadRequestExceptionCopyWith<$Res> implements $AppExceptionCopyWith<$Res> {
  factory $BadRequestExceptionCopyWith(BadRequestException value, $Res Function(BadRequestException) _then) = _$BadRequestExceptionCopyWithImpl;
@override @useResult
$Res call({
 int? statusCode, String? message
});




}
/// @nodoc
class _$BadRequestExceptionCopyWithImpl<$Res>
    implements $BadRequestExceptionCopyWith<$Res> {
  _$BadRequestExceptionCopyWithImpl(this._self, this._then);

  final BadRequestException _self;
  final $Res Function(BadRequestException) _then;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? statusCode = freezed,Object? message = freezed,}) {
  return _then(BadRequestException(
statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UnauthenticatedException implements AppException {
  const UnauthenticatedException({this.message});
  

@override final  String? message;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnauthenticatedExceptionCopyWith<UnauthenticatedException> get copyWith => _$UnauthenticatedExceptionCopyWithImpl<UnauthenticatedException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnauthenticatedException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppException.unauthenticated(message: $message)';
}


}

/// @nodoc
abstract mixin class $UnauthenticatedExceptionCopyWith<$Res> implements $AppExceptionCopyWith<$Res> {
  factory $UnauthenticatedExceptionCopyWith(UnauthenticatedException value, $Res Function(UnauthenticatedException) _then) = _$UnauthenticatedExceptionCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$UnauthenticatedExceptionCopyWithImpl<$Res>
    implements $UnauthenticatedExceptionCopyWith<$Res> {
  _$UnauthenticatedExceptionCopyWithImpl(this._self, this._then);

  final UnauthenticatedException _self;
  final $Res Function(UnauthenticatedException) _then;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(UnauthenticatedException(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UnauthorizedException implements AppException {
  const UnauthorizedException({this.message});
  

@override final  String? message;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnauthorizedExceptionCopyWith<UnauthorizedException> get copyWith => _$UnauthorizedExceptionCopyWithImpl<UnauthorizedException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnauthorizedException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppException.unauthorized(message: $message)';
}


}

/// @nodoc
abstract mixin class $UnauthorizedExceptionCopyWith<$Res> implements $AppExceptionCopyWith<$Res> {
  factory $UnauthorizedExceptionCopyWith(UnauthorizedException value, $Res Function(UnauthorizedException) _then) = _$UnauthorizedExceptionCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$UnauthorizedExceptionCopyWithImpl<$Res>
    implements $UnauthorizedExceptionCopyWith<$Res> {
  _$UnauthorizedExceptionCopyWithImpl(this._self, this._then);

  final UnauthorizedException _self;
  final $Res Function(UnauthorizedException) _then;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(UnauthorizedException(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class TimeoutException implements AppException {
  const TimeoutException({this.message});
  

@override final  String? message;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeoutExceptionCopyWith<TimeoutException> get copyWith => _$TimeoutExceptionCopyWithImpl<TimeoutException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeoutException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppException.timeout(message: $message)';
}


}

/// @nodoc
abstract mixin class $TimeoutExceptionCopyWith<$Res> implements $AppExceptionCopyWith<$Res> {
  factory $TimeoutExceptionCopyWith(TimeoutException value, $Res Function(TimeoutException) _then) = _$TimeoutExceptionCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$TimeoutExceptionCopyWithImpl<$Res>
    implements $TimeoutExceptionCopyWith<$Res> {
  _$TimeoutExceptionCopyWithImpl(this._self, this._then);

  final TimeoutException _self;
  final $Res Function(TimeoutException) _then;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(TimeoutException(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class DataParseException implements AppException {
  const DataParseException({this.message});
  

@override final  String? message;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataParseExceptionCopyWith<DataParseException> get copyWith => _$DataParseExceptionCopyWithImpl<DataParseException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataParseException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppException.dataParse(message: $message)';
}


}

/// @nodoc
abstract mixin class $DataParseExceptionCopyWith<$Res> implements $AppExceptionCopyWith<$Res> {
  factory $DataParseExceptionCopyWith(DataParseException value, $Res Function(DataParseException) _then) = _$DataParseExceptionCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$DataParseExceptionCopyWithImpl<$Res>
    implements $DataParseExceptionCopyWith<$Res> {
  _$DataParseExceptionCopyWithImpl(this._self, this._then);

  final DataParseException _self;
  final $Res Function(DataParseException) _then;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(DataParseException(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class DatabaseException implements AppException {
  const DatabaseException({this.message, this.error});
  

@override final  String? message;
 final  Object? error;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DatabaseExceptionCopyWith<DatabaseException> get copyWith => _$DatabaseExceptionCopyWithImpl<DatabaseException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DatabaseException&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'AppException.database(message: $message, error: $error)';
}


}

/// @nodoc
abstract mixin class $DatabaseExceptionCopyWith<$Res> implements $AppExceptionCopyWith<$Res> {
  factory $DatabaseExceptionCopyWith(DatabaseException value, $Res Function(DatabaseException) _then) = _$DatabaseExceptionCopyWithImpl;
@override @useResult
$Res call({
 String? message, Object? error
});




}
/// @nodoc
class _$DatabaseExceptionCopyWithImpl<$Res>
    implements $DatabaseExceptionCopyWith<$Res> {
  _$DatabaseExceptionCopyWithImpl(this._self, this._then);

  final DatabaseException _self;
  final $Res Function(DatabaseException) _then;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? error = freezed,}) {
  return _then(DatabaseException(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error ,
  ));
}


}

/// @nodoc


class CancelException implements AppException {
  const CancelException({this.message});
  

@override final  String? message;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CancelExceptionCopyWith<CancelException> get copyWith => _$CancelExceptionCopyWithImpl<CancelException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CancelException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppException.cancel(message: $message)';
}


}

/// @nodoc
abstract mixin class $CancelExceptionCopyWith<$Res> implements $AppExceptionCopyWith<$Res> {
  factory $CancelExceptionCopyWith(CancelException value, $Res Function(CancelException) _then) = _$CancelExceptionCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$CancelExceptionCopyWithImpl<$Res>
    implements $CancelExceptionCopyWith<$Res> {
  _$CancelExceptionCopyWithImpl(this._self, this._then);

  final CancelException _self;
  final $Res Function(CancelException) _then;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(CancelException(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UnknownException implements AppException {
  const UnknownException({this.message, this.error});
  

@override final  String? message;
 final  Object? error;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownExceptionCopyWith<UnknownException> get copyWith => _$UnknownExceptionCopyWithImpl<UnknownException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownException&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'AppException.unknown(message: $message, error: $error)';
}


}

/// @nodoc
abstract mixin class $UnknownExceptionCopyWith<$Res> implements $AppExceptionCopyWith<$Res> {
  factory $UnknownExceptionCopyWith(UnknownException value, $Res Function(UnknownException) _then) = _$UnknownExceptionCopyWithImpl;
@override @useResult
$Res call({
 String? message, Object? error
});




}
/// @nodoc
class _$UnknownExceptionCopyWithImpl<$Res>
    implements $UnknownExceptionCopyWith<$Res> {
  _$UnknownExceptionCopyWithImpl(this._self, this._then);

  final UnknownException _self;
  final $Res Function(UnknownException) _then;

/// Create a copy of AppException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? error = freezed,}) {
  return _then(UnknownException(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error ,
  ));
}


}

// dart format on
