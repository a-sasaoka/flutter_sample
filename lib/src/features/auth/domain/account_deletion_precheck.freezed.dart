// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_deletion_precheck.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountDeletionPrecheck {

/// 破壊的削除を始める前に再認証モーダルを表示すべきか
 bool get requiresReauthentication;/// 利用可能な再認証手段
 Set<ReauthMethod> get availableMethods;/// 現在のユーザーのメールアドレス（パスワード再認証モーダル表示用）
 String? get email;
/// Create a copy of AccountDeletionPrecheck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountDeletionPrecheckCopyWith<AccountDeletionPrecheck> get copyWith => _$AccountDeletionPrecheckCopyWithImpl<AccountDeletionPrecheck>(this as AccountDeletionPrecheck, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountDeletionPrecheck&&(identical(other.requiresReauthentication, requiresReauthentication) || other.requiresReauthentication == requiresReauthentication)&&const DeepCollectionEquality().equals(other.availableMethods, availableMethods)&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,requiresReauthentication,const DeepCollectionEquality().hash(availableMethods),email);

@override
String toString() {
  return 'AccountDeletionPrecheck(requiresReauthentication: $requiresReauthentication, availableMethods: $availableMethods, email: $email)';
}


}

/// @nodoc
abstract mixin class $AccountDeletionPrecheckCopyWith<$Res>  {
  factory $AccountDeletionPrecheckCopyWith(AccountDeletionPrecheck value, $Res Function(AccountDeletionPrecheck) _then) = _$AccountDeletionPrecheckCopyWithImpl;
@useResult
$Res call({
 bool requiresReauthentication, Set<ReauthMethod> availableMethods, String? email
});




}
/// @nodoc
class _$AccountDeletionPrecheckCopyWithImpl<$Res>
    implements $AccountDeletionPrecheckCopyWith<$Res> {
  _$AccountDeletionPrecheckCopyWithImpl(this._self, this._then);

  final AccountDeletionPrecheck _self;
  final $Res Function(AccountDeletionPrecheck) _then;

/// Create a copy of AccountDeletionPrecheck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requiresReauthentication = null,Object? availableMethods = null,Object? email = freezed,}) {
  return _then(_self.copyWith(
requiresReauthentication: null == requiresReauthentication ? _self.requiresReauthentication : requiresReauthentication // ignore: cast_nullable_to_non_nullable
as bool,availableMethods: null == availableMethods ? _self.availableMethods : availableMethods // ignore: cast_nullable_to_non_nullable
as Set<ReauthMethod>,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountDeletionPrecheck].
extension AccountDeletionPrecheckPatterns on AccountDeletionPrecheck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountDeletionPrecheck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountDeletionPrecheck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountDeletionPrecheck value)  $default,){
final _that = this;
switch (_that) {
case _AccountDeletionPrecheck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountDeletionPrecheck value)?  $default,){
final _that = this;
switch (_that) {
case _AccountDeletionPrecheck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool requiresReauthentication,  Set<ReauthMethod> availableMethods,  String? email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountDeletionPrecheck() when $default != null:
return $default(_that.requiresReauthentication,_that.availableMethods,_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool requiresReauthentication,  Set<ReauthMethod> availableMethods,  String? email)  $default,) {final _that = this;
switch (_that) {
case _AccountDeletionPrecheck():
return $default(_that.requiresReauthentication,_that.availableMethods,_that.email);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool requiresReauthentication,  Set<ReauthMethod> availableMethods,  String? email)?  $default,) {final _that = this;
switch (_that) {
case _AccountDeletionPrecheck() when $default != null:
return $default(_that.requiresReauthentication,_that.availableMethods,_that.email);case _:
  return null;

}
}

}

/// @nodoc


class _AccountDeletionPrecheck implements AccountDeletionPrecheck {
  const _AccountDeletionPrecheck({required this.requiresReauthentication, required final  Set<ReauthMethod> availableMethods, this.email}): _availableMethods = availableMethods;
  

/// 破壊的削除を始める前に再認証モーダルを表示すべきか
@override final  bool requiresReauthentication;
/// 利用可能な再認証手段
 final  Set<ReauthMethod> _availableMethods;
/// 利用可能な再認証手段
@override Set<ReauthMethod> get availableMethods {
  if (_availableMethods is EqualUnmodifiableSetView) return _availableMethods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_availableMethods);
}

/// 現在のユーザーのメールアドレス（パスワード再認証モーダル表示用）
@override final  String? email;

/// Create a copy of AccountDeletionPrecheck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountDeletionPrecheckCopyWith<_AccountDeletionPrecheck> get copyWith => __$AccountDeletionPrecheckCopyWithImpl<_AccountDeletionPrecheck>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountDeletionPrecheck&&(identical(other.requiresReauthentication, requiresReauthentication) || other.requiresReauthentication == requiresReauthentication)&&const DeepCollectionEquality().equals(other._availableMethods, _availableMethods)&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,requiresReauthentication,const DeepCollectionEquality().hash(_availableMethods),email);

@override
String toString() {
  return 'AccountDeletionPrecheck(requiresReauthentication: $requiresReauthentication, availableMethods: $availableMethods, email: $email)';
}


}

/// @nodoc
abstract mixin class _$AccountDeletionPrecheckCopyWith<$Res> implements $AccountDeletionPrecheckCopyWith<$Res> {
  factory _$AccountDeletionPrecheckCopyWith(_AccountDeletionPrecheck value, $Res Function(_AccountDeletionPrecheck) _then) = __$AccountDeletionPrecheckCopyWithImpl;
@override @useResult
$Res call({
 bool requiresReauthentication, Set<ReauthMethod> availableMethods, String? email
});




}
/// @nodoc
class __$AccountDeletionPrecheckCopyWithImpl<$Res>
    implements _$AccountDeletionPrecheckCopyWith<$Res> {
  __$AccountDeletionPrecheckCopyWithImpl(this._self, this._then);

  final _AccountDeletionPrecheck _self;
  final $Res Function(_AccountDeletionPrecheck) _then;

/// Create a copy of AccountDeletionPrecheck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requiresReauthentication = null,Object? availableMethods = null,Object? email = freezed,}) {
  return _then(_AccountDeletionPrecheck(
requiresReauthentication: null == requiresReauthentication ? _self.requiresReauthentication : requiresReauthentication // ignore: cast_nullable_to_non_nullable
as bool,availableMethods: null == availableMethods ? _self._availableMethods : availableMethods // ignore: cast_nullable_to_non_nullable
as Set<ReauthMethod>,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
