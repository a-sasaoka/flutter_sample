// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_stream_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatStreamEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatStreamEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatStreamEvent()';
}


}

/// @nodoc
class $ChatStreamEventCopyWith<$Res>  {
$ChatStreamEventCopyWith(ChatStreamEvent _, $Res Function(ChatStreamEvent) __);
}


/// Adds pattern-matching-related methods to [ChatStreamEvent].
extension ChatStreamEventPatterns on ChatStreamEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChatStreamEventText value)?  text,TResult Function( ChatStreamEventFunctionCall value)?  functionCall,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChatStreamEventText() when text != null:
return text(_that);case ChatStreamEventFunctionCall() when functionCall != null:
return functionCall(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChatStreamEventText value)  text,required TResult Function( ChatStreamEventFunctionCall value)  functionCall,}){
final _that = this;
switch (_that) {
case ChatStreamEventText():
return text(_that);case ChatStreamEventFunctionCall():
return functionCall(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChatStreamEventText value)?  text,TResult? Function( ChatStreamEventFunctionCall value)?  functionCall,}){
final _that = this;
switch (_that) {
case ChatStreamEventText() when text != null:
return text(_that);case ChatStreamEventFunctionCall() when functionCall != null:
return functionCall(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  text,TResult Function( String name,  Map<String, Object?> args,  String? id)?  functionCall,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChatStreamEventText() when text != null:
return text(_that.text);case ChatStreamEventFunctionCall() when functionCall != null:
return functionCall(_that.name,_that.args,_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  text,required TResult Function( String name,  Map<String, Object?> args,  String? id)  functionCall,}) {final _that = this;
switch (_that) {
case ChatStreamEventText():
return text(_that.text);case ChatStreamEventFunctionCall():
return functionCall(_that.name,_that.args,_that.id);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  text,TResult? Function( String name,  Map<String, Object?> args,  String? id)?  functionCall,}) {final _that = this;
switch (_that) {
case ChatStreamEventText() when text != null:
return text(_that.text);case ChatStreamEventFunctionCall() when functionCall != null:
return functionCall(_that.name,_that.args,_that.id);case _:
  return null;

}
}

}

/// @nodoc


class ChatStreamEventText implements ChatStreamEvent {
  const ChatStreamEventText(this.text);
  

 final  String text;

/// Create a copy of ChatStreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStreamEventTextCopyWith<ChatStreamEventText> get copyWith => _$ChatStreamEventTextCopyWithImpl<ChatStreamEventText>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatStreamEventText&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'ChatStreamEvent.text(text: $text)';
}


}

/// @nodoc
abstract mixin class $ChatStreamEventTextCopyWith<$Res> implements $ChatStreamEventCopyWith<$Res> {
  factory $ChatStreamEventTextCopyWith(ChatStreamEventText value, $Res Function(ChatStreamEventText) _then) = _$ChatStreamEventTextCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$ChatStreamEventTextCopyWithImpl<$Res>
    implements $ChatStreamEventTextCopyWith<$Res> {
  _$ChatStreamEventTextCopyWithImpl(this._self, this._then);

  final ChatStreamEventText _self;
  final $Res Function(ChatStreamEventText) _then;

/// Create a copy of ChatStreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(ChatStreamEventText(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ChatStreamEventFunctionCall implements ChatStreamEvent {
  const ChatStreamEventFunctionCall({required this.name, required final  Map<String, Object?> args, this.id}): _args = args;
  

 final  String name;
 final  Map<String, Object?> _args;
 Map<String, Object?> get args {
  if (_args is EqualUnmodifiableMapView) return _args;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_args);
}

 final  String? id;

/// Create a copy of ChatStreamEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStreamEventFunctionCallCopyWith<ChatStreamEventFunctionCall> get copyWith => _$ChatStreamEventFunctionCallCopyWithImpl<ChatStreamEventFunctionCall>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatStreamEventFunctionCall&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._args, _args)&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_args),id);

@override
String toString() {
  return 'ChatStreamEvent.functionCall(name: $name, args: $args, id: $id)';
}


}

/// @nodoc
abstract mixin class $ChatStreamEventFunctionCallCopyWith<$Res> implements $ChatStreamEventCopyWith<$Res> {
  factory $ChatStreamEventFunctionCallCopyWith(ChatStreamEventFunctionCall value, $Res Function(ChatStreamEventFunctionCall) _then) = _$ChatStreamEventFunctionCallCopyWithImpl;
@useResult
$Res call({
 String name, Map<String, Object?> args, String? id
});




}
/// @nodoc
class _$ChatStreamEventFunctionCallCopyWithImpl<$Res>
    implements $ChatStreamEventFunctionCallCopyWith<$Res> {
  _$ChatStreamEventFunctionCallCopyWithImpl(this._self, this._then);

  final ChatStreamEventFunctionCall _self;
  final $Res Function(ChatStreamEventFunctionCall) _then;

/// Create a copy of ChatStreamEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? args = null,Object? id = freezed,}) {
  return _then(ChatStreamEventFunctionCall(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self._args : args // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
