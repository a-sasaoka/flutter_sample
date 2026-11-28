// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_session_lock.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrackedAuthSession {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackedAuthSession);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackedAuthSession()';
}


}

/// @nodoc
class $TrackedAuthSessionCopyWith<$Res>  {
$TrackedAuthSessionCopyWith(TrackedAuthSession _, $Res Function(TrackedAuthSession) __);
}


/// Adds pattern-matching-related methods to [TrackedAuthSession].
extension TrackedAuthSessionPatterns on TrackedAuthSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SignedOutTrackedAuthSession value)?  signedOut,TResult Function( AuthenticatedTrackedAuthSession value)?  authenticated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SignedOutTrackedAuthSession() when signedOut != null:
return signedOut(_that);case AuthenticatedTrackedAuthSession() when authenticated != null:
return authenticated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SignedOutTrackedAuthSession value)  signedOut,required TResult Function( AuthenticatedTrackedAuthSession value)  authenticated,}){
final _that = this;
switch (_that) {
case SignedOutTrackedAuthSession():
return signedOut(_that);case AuthenticatedTrackedAuthSession():
return authenticated(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SignedOutTrackedAuthSession value)?  signedOut,TResult? Function( AuthenticatedTrackedAuthSession value)?  authenticated,}){
final _that = this;
switch (_that) {
case SignedOutTrackedAuthSession() when signedOut != null:
return signedOut(_that);case AuthenticatedTrackedAuthSession() when authenticated != null:
return authenticated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  signedOut,TResult Function( String? accessToken,  String? userId,  String? email)?  authenticated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SignedOutTrackedAuthSession() when signedOut != null:
return signedOut();case AuthenticatedTrackedAuthSession() when authenticated != null:
return authenticated(_that.accessToken,_that.userId,_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  signedOut,required TResult Function( String? accessToken,  String? userId,  String? email)  authenticated,}) {final _that = this;
switch (_that) {
case SignedOutTrackedAuthSession():
return signedOut();case AuthenticatedTrackedAuthSession():
return authenticated(_that.accessToken,_that.userId,_that.email);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  signedOut,TResult? Function( String? accessToken,  String? userId,  String? email)?  authenticated,}) {final _that = this;
switch (_that) {
case SignedOutTrackedAuthSession() when signedOut != null:
return signedOut();case AuthenticatedTrackedAuthSession() when authenticated != null:
return authenticated(_that.accessToken,_that.userId,_that.email);case _:
  return null;

}
}

}

/// @nodoc


class SignedOutTrackedAuthSession implements TrackedAuthSession {
  const SignedOutTrackedAuthSession();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignedOutTrackedAuthSession);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackedAuthSession.signedOut()';
}


}




/// @nodoc


class AuthenticatedTrackedAuthSession implements TrackedAuthSession {
  const AuthenticatedTrackedAuthSession({this.accessToken, this.userId, this.email});
  

/// 現在の識別情報に紐付くアクセストークン
 final  String? accessToken;
/// ユーザーID（`sub` または保存済み `customUserId`）
 final  String? userId;
/// メールアドレス
 final  String? email;

/// Create a copy of TrackedAuthSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthenticatedTrackedAuthSessionCopyWith<AuthenticatedTrackedAuthSession> get copyWith => _$AuthenticatedTrackedAuthSessionCopyWithImpl<AuthenticatedTrackedAuthSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthenticatedTrackedAuthSession&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,accessToken,userId,email);

@override
String toString() {
  return 'TrackedAuthSession.authenticated(accessToken: $accessToken, userId: $userId, email: $email)';
}


}

/// @nodoc
abstract mixin class $AuthenticatedTrackedAuthSessionCopyWith<$Res> implements $TrackedAuthSessionCopyWith<$Res> {
  factory $AuthenticatedTrackedAuthSessionCopyWith(AuthenticatedTrackedAuthSession value, $Res Function(AuthenticatedTrackedAuthSession) _then) = _$AuthenticatedTrackedAuthSessionCopyWithImpl;
@useResult
$Res call({
 String? accessToken, String? userId, String? email
});




}
/// @nodoc
class _$AuthenticatedTrackedAuthSessionCopyWithImpl<$Res>
    implements $AuthenticatedTrackedAuthSessionCopyWith<$Res> {
  _$AuthenticatedTrackedAuthSessionCopyWithImpl(this._self, this._then);

  final AuthenticatedTrackedAuthSession _self;
  final $Res Function(AuthenticatedTrackedAuthSession) _then;

/// Create a copy of TrackedAuthSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? accessToken = freezed,Object? userId = freezed,Object? email = freezed,}) {
  return _then(AuthenticatedTrackedAuthSession(
accessToken: freezed == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
