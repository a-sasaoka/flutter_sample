// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qr_scanner_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QrScannerState {

 bool get isTorchOn;
/// Create a copy of QrScannerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QrScannerStateCopyWith<QrScannerState> get copyWith => _$QrScannerStateCopyWithImpl<QrScannerState>(this as QrScannerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrScannerState&&(identical(other.isTorchOn, isTorchOn) || other.isTorchOn == isTorchOn));
}


@override
int get hashCode => Object.hash(runtimeType,isTorchOn);

@override
String toString() {
  return 'QrScannerState(isTorchOn: $isTorchOn)';
}


}

/// @nodoc
abstract mixin class $QrScannerStateCopyWith<$Res>  {
  factory $QrScannerStateCopyWith(QrScannerState value, $Res Function(QrScannerState) _then) = _$QrScannerStateCopyWithImpl;
@useResult
$Res call({
 bool isTorchOn
});




}
/// @nodoc
class _$QrScannerStateCopyWithImpl<$Res>
    implements $QrScannerStateCopyWith<$Res> {
  _$QrScannerStateCopyWithImpl(this._self, this._then);

  final QrScannerState _self;
  final $Res Function(QrScannerState) _then;

/// Create a copy of QrScannerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isTorchOn = null,}) {
  return _then(_self.copyWith(
isTorchOn: null == isTorchOn ? _self.isTorchOn : isTorchOn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [QrScannerState].
extension QrScannerStatePatterns on QrScannerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( QrScannerScanning value)?  scanning,TResult Function( QrScannerProcessingImage value)?  processingImage,TResult Function( QrScannerPaused value)?  paused,required TResult orElse(),}){
final _that = this;
switch (_that) {
case QrScannerScanning() when scanning != null:
return scanning(_that);case QrScannerProcessingImage() when processingImage != null:
return processingImage(_that);case QrScannerPaused() when paused != null:
return paused(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( QrScannerScanning value)  scanning,required TResult Function( QrScannerProcessingImage value)  processingImage,required TResult Function( QrScannerPaused value)  paused,}){
final _that = this;
switch (_that) {
case QrScannerScanning():
return scanning(_that);case QrScannerProcessingImage():
return processingImage(_that);case QrScannerPaused():
return paused(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( QrScannerScanning value)?  scanning,TResult? Function( QrScannerProcessingImage value)?  processingImage,TResult? Function( QrScannerPaused value)?  paused,}){
final _that = this;
switch (_that) {
case QrScannerScanning() when scanning != null:
return scanning(_that);case QrScannerProcessingImage() when processingImage != null:
return processingImage(_that);case QrScannerPaused() when paused != null:
return paused(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( bool isTorchOn)?  scanning,TResult Function( bool isTorchOn)?  processingImage,TResult Function( bool isTorchOn)?  paused,required TResult orElse(),}) {final _that = this;
switch (_that) {
case QrScannerScanning() when scanning != null:
return scanning(_that.isTorchOn);case QrScannerProcessingImage() when processingImage != null:
return processingImage(_that.isTorchOn);case QrScannerPaused() when paused != null:
return paused(_that.isTorchOn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( bool isTorchOn)  scanning,required TResult Function( bool isTorchOn)  processingImage,required TResult Function( bool isTorchOn)  paused,}) {final _that = this;
switch (_that) {
case QrScannerScanning():
return scanning(_that.isTorchOn);case QrScannerProcessingImage():
return processingImage(_that.isTorchOn);case QrScannerPaused():
return paused(_that.isTorchOn);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( bool isTorchOn)?  scanning,TResult? Function( bool isTorchOn)?  processingImage,TResult? Function( bool isTorchOn)?  paused,}) {final _that = this;
switch (_that) {
case QrScannerScanning() when scanning != null:
return scanning(_that.isTorchOn);case QrScannerProcessingImage() when processingImage != null:
return processingImage(_that.isTorchOn);case QrScannerPaused() when paused != null:
return paused(_that.isTorchOn);case _:
  return null;

}
}

}

/// @nodoc


class QrScannerScanning implements QrScannerState {
  const QrScannerScanning({this.isTorchOn = false});
  

@override@JsonKey() final  bool isTorchOn;

/// Create a copy of QrScannerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QrScannerScanningCopyWith<QrScannerScanning> get copyWith => _$QrScannerScanningCopyWithImpl<QrScannerScanning>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrScannerScanning&&(identical(other.isTorchOn, isTorchOn) || other.isTorchOn == isTorchOn));
}


@override
int get hashCode => Object.hash(runtimeType,isTorchOn);

@override
String toString() {
  return 'QrScannerState.scanning(isTorchOn: $isTorchOn)';
}


}

/// @nodoc
abstract mixin class $QrScannerScanningCopyWith<$Res> implements $QrScannerStateCopyWith<$Res> {
  factory $QrScannerScanningCopyWith(QrScannerScanning value, $Res Function(QrScannerScanning) _then) = _$QrScannerScanningCopyWithImpl;
@override @useResult
$Res call({
 bool isTorchOn
});




}
/// @nodoc
class _$QrScannerScanningCopyWithImpl<$Res>
    implements $QrScannerScanningCopyWith<$Res> {
  _$QrScannerScanningCopyWithImpl(this._self, this._then);

  final QrScannerScanning _self;
  final $Res Function(QrScannerScanning) _then;

/// Create a copy of QrScannerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isTorchOn = null,}) {
  return _then(QrScannerScanning(
isTorchOn: null == isTorchOn ? _self.isTorchOn : isTorchOn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class QrScannerProcessingImage implements QrScannerState {
  const QrScannerProcessingImage({this.isTorchOn = false});
  

@override@JsonKey() final  bool isTorchOn;

/// Create a copy of QrScannerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QrScannerProcessingImageCopyWith<QrScannerProcessingImage> get copyWith => _$QrScannerProcessingImageCopyWithImpl<QrScannerProcessingImage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrScannerProcessingImage&&(identical(other.isTorchOn, isTorchOn) || other.isTorchOn == isTorchOn));
}


@override
int get hashCode => Object.hash(runtimeType,isTorchOn);

@override
String toString() {
  return 'QrScannerState.processingImage(isTorchOn: $isTorchOn)';
}


}

/// @nodoc
abstract mixin class $QrScannerProcessingImageCopyWith<$Res> implements $QrScannerStateCopyWith<$Res> {
  factory $QrScannerProcessingImageCopyWith(QrScannerProcessingImage value, $Res Function(QrScannerProcessingImage) _then) = _$QrScannerProcessingImageCopyWithImpl;
@override @useResult
$Res call({
 bool isTorchOn
});




}
/// @nodoc
class _$QrScannerProcessingImageCopyWithImpl<$Res>
    implements $QrScannerProcessingImageCopyWith<$Res> {
  _$QrScannerProcessingImageCopyWithImpl(this._self, this._then);

  final QrScannerProcessingImage _self;
  final $Res Function(QrScannerProcessingImage) _then;

/// Create a copy of QrScannerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isTorchOn = null,}) {
  return _then(QrScannerProcessingImage(
isTorchOn: null == isTorchOn ? _self.isTorchOn : isTorchOn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class QrScannerPaused implements QrScannerState {
  const QrScannerPaused({this.isTorchOn = false});
  

@override@JsonKey() final  bool isTorchOn;

/// Create a copy of QrScannerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QrScannerPausedCopyWith<QrScannerPaused> get copyWith => _$QrScannerPausedCopyWithImpl<QrScannerPaused>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrScannerPaused&&(identical(other.isTorchOn, isTorchOn) || other.isTorchOn == isTorchOn));
}


@override
int get hashCode => Object.hash(runtimeType,isTorchOn);

@override
String toString() {
  return 'QrScannerState.paused(isTorchOn: $isTorchOn)';
}


}

/// @nodoc
abstract mixin class $QrScannerPausedCopyWith<$Res> implements $QrScannerStateCopyWith<$Res> {
  factory $QrScannerPausedCopyWith(QrScannerPaused value, $Res Function(QrScannerPaused) _then) = _$QrScannerPausedCopyWithImpl;
@override @useResult
$Res call({
 bool isTorchOn
});




}
/// @nodoc
class _$QrScannerPausedCopyWithImpl<$Res>
    implements $QrScannerPausedCopyWith<$Res> {
  _$QrScannerPausedCopyWithImpl(this._self, this._then);

  final QrScannerPaused _self;
  final $Res Function(QrScannerPaused) _then;

/// Create a copy of QrScannerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isTorchOn = null,}) {
  return _then(QrScannerPaused(
isTorchOn: null == isTorchOn ? _self.isTorchOn : isTorchOn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
