// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qr_image_pick_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QrImagePickResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrImagePickResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'QrImagePickResult()';
}


}

/// @nodoc
class $QrImagePickResultCopyWith<$Res>  {
$QrImagePickResultCopyWith(QrImagePickResult _, $Res Function(QrImagePickResult) __);
}


/// Adds pattern-matching-related methods to [QrImagePickResult].
extension QrImagePickResultPatterns on QrImagePickResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( QrImagePickSuccess value)?  success,TResult Function( QrImagePickCanceled value)?  canceled,TResult Function( QrImagePickNotFound value)?  notFound,required TResult orElse(),}){
final _that = this;
switch (_that) {
case QrImagePickSuccess() when success != null:
return success(_that);case QrImagePickCanceled() when canceled != null:
return canceled(_that);case QrImagePickNotFound() when notFound != null:
return notFound(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( QrImagePickSuccess value)  success,required TResult Function( QrImagePickCanceled value)  canceled,required TResult Function( QrImagePickNotFound value)  notFound,}){
final _that = this;
switch (_that) {
case QrImagePickSuccess():
return success(_that);case QrImagePickCanceled():
return canceled(_that);case QrImagePickNotFound():
return notFound(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( QrImagePickSuccess value)?  success,TResult? Function( QrImagePickCanceled value)?  canceled,TResult? Function( QrImagePickNotFound value)?  notFound,}){
final _that = this;
switch (_that) {
case QrImagePickSuccess() when success != null:
return success(_that);case QrImagePickCanceled() when canceled != null:
return canceled(_that);case QrImagePickNotFound() when notFound != null:
return notFound(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String rawValue)?  success,TResult Function()?  canceled,TResult Function()?  notFound,required TResult orElse(),}) {final _that = this;
switch (_that) {
case QrImagePickSuccess() when success != null:
return success(_that.rawValue);case QrImagePickCanceled() when canceled != null:
return canceled();case QrImagePickNotFound() when notFound != null:
return notFound();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String rawValue)  success,required TResult Function()  canceled,required TResult Function()  notFound,}) {final _that = this;
switch (_that) {
case QrImagePickSuccess():
return success(_that.rawValue);case QrImagePickCanceled():
return canceled();case QrImagePickNotFound():
return notFound();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String rawValue)?  success,TResult? Function()?  canceled,TResult? Function()?  notFound,}) {final _that = this;
switch (_that) {
case QrImagePickSuccess() when success != null:
return success(_that.rawValue);case QrImagePickCanceled() when canceled != null:
return canceled();case QrImagePickNotFound() when notFound != null:
return notFound();case _:
  return null;

}
}

}

/// @nodoc


class QrImagePickSuccess implements QrImagePickResult {
  const QrImagePickSuccess(this.rawValue);
  

 final  String rawValue;

/// Create a copy of QrImagePickResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QrImagePickSuccessCopyWith<QrImagePickSuccess> get copyWith => _$QrImagePickSuccessCopyWithImpl<QrImagePickSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrImagePickSuccess&&(identical(other.rawValue, rawValue) || other.rawValue == rawValue));
}


@override
int get hashCode => Object.hash(runtimeType,rawValue);

@override
String toString() {
  return 'QrImagePickResult.success(rawValue: $rawValue)';
}


}

/// @nodoc
abstract mixin class $QrImagePickSuccessCopyWith<$Res> implements $QrImagePickResultCopyWith<$Res> {
  factory $QrImagePickSuccessCopyWith(QrImagePickSuccess value, $Res Function(QrImagePickSuccess) _then) = _$QrImagePickSuccessCopyWithImpl;
@useResult
$Res call({
 String rawValue
});




}
/// @nodoc
class _$QrImagePickSuccessCopyWithImpl<$Res>
    implements $QrImagePickSuccessCopyWith<$Res> {
  _$QrImagePickSuccessCopyWithImpl(this._self, this._then);

  final QrImagePickSuccess _self;
  final $Res Function(QrImagePickSuccess) _then;

/// Create a copy of QrImagePickResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rawValue = null,}) {
  return _then(QrImagePickSuccess(
null == rawValue ? _self.rawValue : rawValue // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class QrImagePickCanceled implements QrImagePickResult {
  const QrImagePickCanceled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrImagePickCanceled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'QrImagePickResult.canceled()';
}


}




/// @nodoc


class QrImagePickNotFound implements QrImagePickResult {
  const QrImagePickNotFound();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrImagePickNotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'QrImagePickResult.notFound()';
}


}




// dart format on
