// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reauth_exception.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReauthException {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReauthException);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReauthException()';
}


}

/// @nodoc
class $ReauthExceptionCopyWith<$Res>  {
$ReauthExceptionCopyWith(ReauthException _, $Res Function(ReauthException) __);
}


/// Adds pattern-matching-related methods to [ReauthException].
extension ReauthExceptionPatterns on ReauthException {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReauthRequiresRecentLoginException value)?  requiresRecentLogin,TResult Function( ReauthWrongPasswordException value)?  wrongPassword,TResult Function( ReauthUserMismatchException value)?  userMismatch,TResult Function( ReauthCancelledException value)?  cancelled,TResult Function( ReauthTooManyRequestsException value)?  tooManyRequests,TResult Function( ReauthMissingEmailException value)?  missingEmail,TResult Function( ReauthInvalidCredentialException value)?  invalidCredential,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReauthRequiresRecentLoginException() when requiresRecentLogin != null:
return requiresRecentLogin(_that);case ReauthWrongPasswordException() when wrongPassword != null:
return wrongPassword(_that);case ReauthUserMismatchException() when userMismatch != null:
return userMismatch(_that);case ReauthCancelledException() when cancelled != null:
return cancelled(_that);case ReauthTooManyRequestsException() when tooManyRequests != null:
return tooManyRequests(_that);case ReauthMissingEmailException() when missingEmail != null:
return missingEmail(_that);case ReauthInvalidCredentialException() when invalidCredential != null:
return invalidCredential(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReauthRequiresRecentLoginException value)  requiresRecentLogin,required TResult Function( ReauthWrongPasswordException value)  wrongPassword,required TResult Function( ReauthUserMismatchException value)  userMismatch,required TResult Function( ReauthCancelledException value)  cancelled,required TResult Function( ReauthTooManyRequestsException value)  tooManyRequests,required TResult Function( ReauthMissingEmailException value)  missingEmail,required TResult Function( ReauthInvalidCredentialException value)  invalidCredential,}){
final _that = this;
switch (_that) {
case ReauthRequiresRecentLoginException():
return requiresRecentLogin(_that);case ReauthWrongPasswordException():
return wrongPassword(_that);case ReauthUserMismatchException():
return userMismatch(_that);case ReauthCancelledException():
return cancelled(_that);case ReauthTooManyRequestsException():
return tooManyRequests(_that);case ReauthMissingEmailException():
return missingEmail(_that);case ReauthInvalidCredentialException():
return invalidCredential(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReauthRequiresRecentLoginException value)?  requiresRecentLogin,TResult? Function( ReauthWrongPasswordException value)?  wrongPassword,TResult? Function( ReauthUserMismatchException value)?  userMismatch,TResult? Function( ReauthCancelledException value)?  cancelled,TResult? Function( ReauthTooManyRequestsException value)?  tooManyRequests,TResult? Function( ReauthMissingEmailException value)?  missingEmail,TResult? Function( ReauthInvalidCredentialException value)?  invalidCredential,}){
final _that = this;
switch (_that) {
case ReauthRequiresRecentLoginException() when requiresRecentLogin != null:
return requiresRecentLogin(_that);case ReauthWrongPasswordException() when wrongPassword != null:
return wrongPassword(_that);case ReauthUserMismatchException() when userMismatch != null:
return userMismatch(_that);case ReauthCancelledException() when cancelled != null:
return cancelled(_that);case ReauthTooManyRequestsException() when tooManyRequests != null:
return tooManyRequests(_that);case ReauthMissingEmailException() when missingEmail != null:
return missingEmail(_that);case ReauthInvalidCredentialException() when invalidCredential != null:
return invalidCredential(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  requiresRecentLogin,TResult Function()?  wrongPassword,TResult Function()?  userMismatch,TResult Function()?  cancelled,TResult Function()?  tooManyRequests,TResult Function()?  missingEmail,TResult Function()?  invalidCredential,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReauthRequiresRecentLoginException() when requiresRecentLogin != null:
return requiresRecentLogin();case ReauthWrongPasswordException() when wrongPassword != null:
return wrongPassword();case ReauthUserMismatchException() when userMismatch != null:
return userMismatch();case ReauthCancelledException() when cancelled != null:
return cancelled();case ReauthTooManyRequestsException() when tooManyRequests != null:
return tooManyRequests();case ReauthMissingEmailException() when missingEmail != null:
return missingEmail();case ReauthInvalidCredentialException() when invalidCredential != null:
return invalidCredential();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  requiresRecentLogin,required TResult Function()  wrongPassword,required TResult Function()  userMismatch,required TResult Function()  cancelled,required TResult Function()  tooManyRequests,required TResult Function()  missingEmail,required TResult Function()  invalidCredential,}) {final _that = this;
switch (_that) {
case ReauthRequiresRecentLoginException():
return requiresRecentLogin();case ReauthWrongPasswordException():
return wrongPassword();case ReauthUserMismatchException():
return userMismatch();case ReauthCancelledException():
return cancelled();case ReauthTooManyRequestsException():
return tooManyRequests();case ReauthMissingEmailException():
return missingEmail();case ReauthInvalidCredentialException():
return invalidCredential();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  requiresRecentLogin,TResult? Function()?  wrongPassword,TResult? Function()?  userMismatch,TResult? Function()?  cancelled,TResult? Function()?  tooManyRequests,TResult? Function()?  missingEmail,TResult? Function()?  invalidCredential,}) {final _that = this;
switch (_that) {
case ReauthRequiresRecentLoginException() when requiresRecentLogin != null:
return requiresRecentLogin();case ReauthWrongPasswordException() when wrongPassword != null:
return wrongPassword();case ReauthUserMismatchException() when userMismatch != null:
return userMismatch();case ReauthCancelledException() when cancelled != null:
return cancelled();case ReauthTooManyRequestsException() when tooManyRequests != null:
return tooManyRequests();case ReauthMissingEmailException() when missingEmail != null:
return missingEmail();case ReauthInvalidCredentialException() when invalidCredential != null:
return invalidCredential();case _:
  return null;

}
}

}

/// @nodoc


class ReauthRequiresRecentLoginException implements ReauthException {
  const ReauthRequiresRecentLoginException();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReauthRequiresRecentLoginException);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReauthException.requiresRecentLogin()';
}


}




/// @nodoc


class ReauthWrongPasswordException implements ReauthException {
  const ReauthWrongPasswordException();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReauthWrongPasswordException);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReauthException.wrongPassword()';
}


}




/// @nodoc


class ReauthUserMismatchException implements ReauthException {
  const ReauthUserMismatchException();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReauthUserMismatchException);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReauthException.userMismatch()';
}


}




/// @nodoc


class ReauthCancelledException implements ReauthException {
  const ReauthCancelledException();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReauthCancelledException);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReauthException.cancelled()';
}


}




/// @nodoc


class ReauthTooManyRequestsException implements ReauthException {
  const ReauthTooManyRequestsException();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReauthTooManyRequestsException);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReauthException.tooManyRequests()';
}


}




/// @nodoc


class ReauthMissingEmailException implements ReauthException {
  const ReauthMissingEmailException();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReauthMissingEmailException);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReauthException.missingEmail()';
}


}




/// @nodoc


class ReauthInvalidCredentialException implements ReauthException {
  const ReauthInvalidCredentialException();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReauthInvalidCredentialException);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReauthException.invalidCredential()';
}


}




// dart format on
