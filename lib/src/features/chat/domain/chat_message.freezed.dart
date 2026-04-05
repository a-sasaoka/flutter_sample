// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatMessage {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatMessage()';
}


}

/// @nodoc
class $ChatMessageCopyWith<$Res>  {
$ChatMessageCopyWith(ChatMessage _, $Res Function(ChatMessage) __);
}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChatMessageUser value)?  user,TResult Function( ChatMessageAi value)?  ai,TResult Function( ChatMessageLoading value)?  loading,TResult Function( ChatMessageError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChatMessageUser() when user != null:
return user(_that);case ChatMessageAi() when ai != null:
return ai(_that);case ChatMessageLoading() when loading != null:
return loading(_that);case ChatMessageError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChatMessageUser value)  user,required TResult Function( ChatMessageAi value)  ai,required TResult Function( ChatMessageLoading value)  loading,required TResult Function( ChatMessageError value)  error,}){
final _that = this;
switch (_that) {
case ChatMessageUser():
return user(_that);case ChatMessageAi():
return ai(_that);case ChatMessageLoading():
return loading(_that);case ChatMessageError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChatMessageUser value)?  user,TResult? Function( ChatMessageAi value)?  ai,TResult? Function( ChatMessageLoading value)?  loading,TResult? Function( ChatMessageError value)?  error,}){
final _that = this;
switch (_that) {
case ChatMessageUser() when user != null:
return user(_that);case ChatMessageAi() when ai != null:
return ai(_that);case ChatMessageLoading() when loading != null:
return loading(_that);case ChatMessageError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  user,TResult Function( String text)?  ai,TResult Function()?  loading,TResult Function( Object error)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChatMessageUser() when user != null:
return user(_that.text);case ChatMessageAi() when ai != null:
return ai(_that.text);case ChatMessageLoading() when loading != null:
return loading();case ChatMessageError() when error != null:
return error(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  user,required TResult Function( String text)  ai,required TResult Function()  loading,required TResult Function( Object error)  error,}) {final _that = this;
switch (_that) {
case ChatMessageUser():
return user(_that.text);case ChatMessageAi():
return ai(_that.text);case ChatMessageLoading():
return loading();case ChatMessageError():
return error(_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  user,TResult? Function( String text)?  ai,TResult? Function()?  loading,TResult? Function( Object error)?  error,}) {final _that = this;
switch (_that) {
case ChatMessageUser() when user != null:
return user(_that.text);case ChatMessageAi() when ai != null:
return ai(_that.text);case ChatMessageLoading() when loading != null:
return loading();case ChatMessageError() when error != null:
return error(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class ChatMessageUser implements ChatMessage {
  const ChatMessageUser({required this.text});
  

 final  String text;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageUserCopyWith<ChatMessageUser> get copyWith => _$ChatMessageUserCopyWithImpl<ChatMessageUser>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageUser&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'ChatMessage.user(text: $text)';
}


}

/// @nodoc
abstract mixin class $ChatMessageUserCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory $ChatMessageUserCopyWith(ChatMessageUser value, $Res Function(ChatMessageUser) _then) = _$ChatMessageUserCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$ChatMessageUserCopyWithImpl<$Res>
    implements $ChatMessageUserCopyWith<$Res> {
  _$ChatMessageUserCopyWithImpl(this._self, this._then);

  final ChatMessageUser _self;
  final $Res Function(ChatMessageUser) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(ChatMessageUser(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ChatMessageAi implements ChatMessage {
  const ChatMessageAi({required this.text});
  

 final  String text;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageAiCopyWith<ChatMessageAi> get copyWith => _$ChatMessageAiCopyWithImpl<ChatMessageAi>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageAi&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'ChatMessage.ai(text: $text)';
}


}

/// @nodoc
abstract mixin class $ChatMessageAiCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory $ChatMessageAiCopyWith(ChatMessageAi value, $Res Function(ChatMessageAi) _then) = _$ChatMessageAiCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$ChatMessageAiCopyWithImpl<$Res>
    implements $ChatMessageAiCopyWith<$Res> {
  _$ChatMessageAiCopyWithImpl(this._self, this._then);

  final ChatMessageAi _self;
  final $Res Function(ChatMessageAi) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(ChatMessageAi(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ChatMessageLoading implements ChatMessage {
  const ChatMessageLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatMessage.loading()';
}


}




/// @nodoc


class ChatMessageError implements ChatMessage {
  const ChatMessageError({required this.error});
  

 final  Object error;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageErrorCopyWith<ChatMessageError> get copyWith => _$ChatMessageErrorCopyWithImpl<ChatMessageError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ChatMessage.error(error: $error)';
}


}

/// @nodoc
abstract mixin class $ChatMessageErrorCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory $ChatMessageErrorCopyWith(ChatMessageError value, $Res Function(ChatMessageError) _then) = _$ChatMessageErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$ChatMessageErrorCopyWithImpl<$Res>
    implements $ChatMessageErrorCopyWith<$Res> {
  _$ChatMessageErrorCopyWithImpl(this._self, this._then);

  final ChatMessageError _self;
  final $Res Function(ChatMessageError) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(ChatMessageError(
error: null == error ? _self.error : error ,
  ));
}


}

// dart format on
