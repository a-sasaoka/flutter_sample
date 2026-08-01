// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_lock_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppLockState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppLockState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppLockState()';
}


}

/// @nodoc
class $AppLockStateCopyWith<$Res>  {
$AppLockStateCopyWith(AppLockState _, $Res Function(AppLockState) __);
}


/// Adds pattern-matching-related methods to [AppLockState].
extension AppLockStatePatterns on AppLockState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AppLockStateDisabled value)?  disabled,TResult Function( AppLockStateSetupRequired value)?  setupRequired,TResult Function( AppLockStateLocked value)?  locked,TResult Function( AppLockStateUnlocked value)?  unlocked,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AppLockStateDisabled() when disabled != null:
return disabled(_that);case AppLockStateSetupRequired() when setupRequired != null:
return setupRequired(_that);case AppLockStateLocked() when locked != null:
return locked(_that);case AppLockStateUnlocked() when unlocked != null:
return unlocked(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AppLockStateDisabled value)  disabled,required TResult Function( AppLockStateSetupRequired value)  setupRequired,required TResult Function( AppLockStateLocked value)  locked,required TResult Function( AppLockStateUnlocked value)  unlocked,}){
final _that = this;
switch (_that) {
case AppLockStateDisabled():
return disabled(_that);case AppLockStateSetupRequired():
return setupRequired(_that);case AppLockStateLocked():
return locked(_that);case AppLockStateUnlocked():
return unlocked(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AppLockStateDisabled value)?  disabled,TResult? Function( AppLockStateSetupRequired value)?  setupRequired,TResult? Function( AppLockStateLocked value)?  locked,TResult? Function( AppLockStateUnlocked value)?  unlocked,}){
final _that = this;
switch (_that) {
case AppLockStateDisabled() when disabled != null:
return disabled(_that);case AppLockStateSetupRequired() when setupRequired != null:
return setupRequired(_that);case AppLockStateLocked() when locked != null:
return locked(_that);case AppLockStateUnlocked() when unlocked != null:
return unlocked(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  disabled,TResult Function()?  setupRequired,TResult Function( bool isBiometricEnabled)?  locked,TResult Function( bool isBiometricEnabled)?  unlocked,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AppLockStateDisabled() when disabled != null:
return disabled();case AppLockStateSetupRequired() when setupRequired != null:
return setupRequired();case AppLockStateLocked() when locked != null:
return locked(_that.isBiometricEnabled);case AppLockStateUnlocked() when unlocked != null:
return unlocked(_that.isBiometricEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  disabled,required TResult Function()  setupRequired,required TResult Function( bool isBiometricEnabled)  locked,required TResult Function( bool isBiometricEnabled)  unlocked,}) {final _that = this;
switch (_that) {
case AppLockStateDisabled():
return disabled();case AppLockStateSetupRequired():
return setupRequired();case AppLockStateLocked():
return locked(_that.isBiometricEnabled);case AppLockStateUnlocked():
return unlocked(_that.isBiometricEnabled);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  disabled,TResult? Function()?  setupRequired,TResult? Function( bool isBiometricEnabled)?  locked,TResult? Function( bool isBiometricEnabled)?  unlocked,}) {final _that = this;
switch (_that) {
case AppLockStateDisabled() when disabled != null:
return disabled();case AppLockStateSetupRequired() when setupRequired != null:
return setupRequired();case AppLockStateLocked() when locked != null:
return locked(_that.isBiometricEnabled);case AppLockStateUnlocked() when unlocked != null:
return unlocked(_that.isBiometricEnabled);case _:
  return null;

}
}

}

/// @nodoc


class AppLockStateDisabled implements AppLockState {
  const AppLockStateDisabled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppLockStateDisabled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppLockState.disabled()';
}


}




/// @nodoc


class AppLockStateSetupRequired implements AppLockState {
  const AppLockStateSetupRequired();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppLockStateSetupRequired);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppLockState.setupRequired()';
}


}




/// @nodoc


class AppLockStateLocked implements AppLockState {
  const AppLockStateLocked({required this.isBiometricEnabled});
  

 final  bool isBiometricEnabled;

/// Create a copy of AppLockState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppLockStateLockedCopyWith<AppLockStateLocked> get copyWith => _$AppLockStateLockedCopyWithImpl<AppLockStateLocked>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppLockStateLocked&&(identical(other.isBiometricEnabled, isBiometricEnabled) || other.isBiometricEnabled == isBiometricEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,isBiometricEnabled);

@override
String toString() {
  return 'AppLockState.locked(isBiometricEnabled: $isBiometricEnabled)';
}


}

/// @nodoc
abstract mixin class $AppLockStateLockedCopyWith<$Res> implements $AppLockStateCopyWith<$Res> {
  factory $AppLockStateLockedCopyWith(AppLockStateLocked value, $Res Function(AppLockStateLocked) _then) = _$AppLockStateLockedCopyWithImpl;
@useResult
$Res call({
 bool isBiometricEnabled
});




}
/// @nodoc
class _$AppLockStateLockedCopyWithImpl<$Res>
    implements $AppLockStateLockedCopyWith<$Res> {
  _$AppLockStateLockedCopyWithImpl(this._self, this._then);

  final AppLockStateLocked _self;
  final $Res Function(AppLockStateLocked) _then;

/// Create a copy of AppLockState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isBiometricEnabled = null,}) {
  return _then(AppLockStateLocked(
isBiometricEnabled: null == isBiometricEnabled ? _self.isBiometricEnabled : isBiometricEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class AppLockStateUnlocked implements AppLockState {
  const AppLockStateUnlocked({required this.isBiometricEnabled});
  

 final  bool isBiometricEnabled;

/// Create a copy of AppLockState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppLockStateUnlockedCopyWith<AppLockStateUnlocked> get copyWith => _$AppLockStateUnlockedCopyWithImpl<AppLockStateUnlocked>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppLockStateUnlocked&&(identical(other.isBiometricEnabled, isBiometricEnabled) || other.isBiometricEnabled == isBiometricEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,isBiometricEnabled);

@override
String toString() {
  return 'AppLockState.unlocked(isBiometricEnabled: $isBiometricEnabled)';
}


}

/// @nodoc
abstract mixin class $AppLockStateUnlockedCopyWith<$Res> implements $AppLockStateCopyWith<$Res> {
  factory $AppLockStateUnlockedCopyWith(AppLockStateUnlocked value, $Res Function(AppLockStateUnlocked) _then) = _$AppLockStateUnlockedCopyWithImpl;
@useResult
$Res call({
 bool isBiometricEnabled
});




}
/// @nodoc
class _$AppLockStateUnlockedCopyWithImpl<$Res>
    implements $AppLockStateUnlockedCopyWith<$Res> {
  _$AppLockStateUnlockedCopyWithImpl(this._self, this._then);

  final AppLockStateUnlocked _self;
  final $Res Function(AppLockStateUnlocked) _then;

/// Create a copy of AppLockState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isBiometricEnabled = null,}) {
  return _then(AppLockStateUnlocked(
isBiometricEnabled: null == isBiometricEnabled ? _self.isBiometricEnabled : isBiometricEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
