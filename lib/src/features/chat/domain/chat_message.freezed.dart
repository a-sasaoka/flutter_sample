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

 String get id; DateTime get createdAt;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,createdAt);

@override
String toString() {
  return 'ChatMessage(id: $id, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, DateTime createdAt
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String text,  DateTime createdAt)?  user,TResult Function( String id,  String text,  DateTime createdAt)?  ai,TResult Function( String id,  DateTime createdAt)?  loading,TResult Function( String id,  Object error,  DateTime createdAt)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChatMessageUser() when user != null:
return user(_that.id,_that.text,_that.createdAt);case ChatMessageAi() when ai != null:
return ai(_that.id,_that.text,_that.createdAt);case ChatMessageLoading() when loading != null:
return loading(_that.id,_that.createdAt);case ChatMessageError() when error != null:
return error(_that.id,_that.error,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String text,  DateTime createdAt)  user,required TResult Function( String id,  String text,  DateTime createdAt)  ai,required TResult Function( String id,  DateTime createdAt)  loading,required TResult Function( String id,  Object error,  DateTime createdAt)  error,}) {final _that = this;
switch (_that) {
case ChatMessageUser():
return user(_that.id,_that.text,_that.createdAt);case ChatMessageAi():
return ai(_that.id,_that.text,_that.createdAt);case ChatMessageLoading():
return loading(_that.id,_that.createdAt);case ChatMessageError():
return error(_that.id,_that.error,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String text,  DateTime createdAt)?  user,TResult? Function( String id,  String text,  DateTime createdAt)?  ai,TResult? Function( String id,  DateTime createdAt)?  loading,TResult? Function( String id,  Object error,  DateTime createdAt)?  error,}) {final _that = this;
switch (_that) {
case ChatMessageUser() when user != null:
return user(_that.id,_that.text,_that.createdAt);case ChatMessageAi() when ai != null:
return ai(_that.id,_that.text,_that.createdAt);case ChatMessageLoading() when loading != null:
return loading(_that.id,_that.createdAt);case ChatMessageError() when error != null:
return error(_that.id,_that.error,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class ChatMessageUser extends ChatMessage {
  const ChatMessageUser({required this.id, required this.text, required this.createdAt}): super._();
  

@override final  String id;
 final  String text;
@override final  DateTime createdAt;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageUserCopyWith<ChatMessageUser> get copyWith => _$ChatMessageUserCopyWithImpl<ChatMessageUser>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageUser&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,text,createdAt);

@override
String toString() {
  return 'ChatMessage.user(id: $id, text: $text, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ChatMessageUserCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory $ChatMessageUserCopyWith(ChatMessageUser value, $Res Function(ChatMessageUser) _then) = _$ChatMessageUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, DateTime createdAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? createdAt = null,}) {
  return _then(ChatMessageUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class ChatMessageAi extends ChatMessage {
  const ChatMessageAi({required this.id, required this.text, required this.createdAt}): super._();
  

@override final  String id;
 final  String text;
@override final  DateTime createdAt;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageAiCopyWith<ChatMessageAi> get copyWith => _$ChatMessageAiCopyWithImpl<ChatMessageAi>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageAi&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,text,createdAt);

@override
String toString() {
  return 'ChatMessage.ai(id: $id, text: $text, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ChatMessageAiCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory $ChatMessageAiCopyWith(ChatMessageAi value, $Res Function(ChatMessageAi) _then) = _$ChatMessageAiCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, DateTime createdAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? createdAt = null,}) {
  return _then(ChatMessageAi(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class ChatMessageLoading extends ChatMessage {
  const ChatMessageLoading({required this.id, required this.createdAt}): super._();
  

@override final  String id;
@override final  DateTime createdAt;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageLoadingCopyWith<ChatMessageLoading> get copyWith => _$ChatMessageLoadingCopyWithImpl<ChatMessageLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageLoading&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,createdAt);

@override
String toString() {
  return 'ChatMessage.loading(id: $id, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ChatMessageLoadingCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory $ChatMessageLoadingCopyWith(ChatMessageLoading value, $Res Function(ChatMessageLoading) _then) = _$ChatMessageLoadingCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime createdAt
});




}
/// @nodoc
class _$ChatMessageLoadingCopyWithImpl<$Res>
    implements $ChatMessageLoadingCopyWith<$Res> {
  _$ChatMessageLoadingCopyWithImpl(this._self, this._then);

  final ChatMessageLoading _self;
  final $Res Function(ChatMessageLoading) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? createdAt = null,}) {
  return _then(ChatMessageLoading(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class ChatMessageError extends ChatMessage {
  const ChatMessageError({required this.id, required this.error, required this.createdAt}): super._();
  

@override final  String id;
 final  Object error;
@override final  DateTime createdAt;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageErrorCopyWith<ChatMessageError> get copyWith => _$ChatMessageErrorCopyWithImpl<ChatMessageError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageError&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(error),createdAt);

@override
String toString() {
  return 'ChatMessage.error(id: $id, error: $error, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ChatMessageErrorCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory $ChatMessageErrorCopyWith(ChatMessageError value, $Res Function(ChatMessageError) _then) = _$ChatMessageErrorCopyWithImpl;
@override @useResult
$Res call({
 String id, Object error, DateTime createdAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? error = null,Object? createdAt = null,}) {
  return _then(ChatMessageError(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,error: null == error ? _self.error : error ,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
