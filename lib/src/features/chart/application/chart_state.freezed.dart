// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chart_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChartState {

/// 入力されたデータ項目のリスト
 List<ChartItem> get items;/// 選択されているグラフの種類
 ChartType get chartType;/// 項目名の連番管理用カウンター（削除されても重複しないように管理）
 int get itemCounter;
/// Create a copy of ChartState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartStateCopyWith<ChartState> get copyWith => _$ChartStateCopyWithImpl<ChartState>(this as ChartState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartState&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.chartType, chartType) || other.chartType == chartType)&&(identical(other.itemCounter, itemCounter) || other.itemCounter == itemCounter));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),chartType,itemCounter);

@override
String toString() {
  return 'ChartState(items: $items, chartType: $chartType, itemCounter: $itemCounter)';
}


}

/// @nodoc
abstract mixin class $ChartStateCopyWith<$Res>  {
  factory $ChartStateCopyWith(ChartState value, $Res Function(ChartState) _then) = _$ChartStateCopyWithImpl;
@useResult
$Res call({
 List<ChartItem> items, ChartType chartType, int itemCounter
});




}
/// @nodoc
class _$ChartStateCopyWithImpl<$Res>
    implements $ChartStateCopyWith<$Res> {
  _$ChartStateCopyWithImpl(this._self, this._then);

  final ChartState _self;
  final $Res Function(ChartState) _then;

/// Create a copy of ChartState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? chartType = null,Object? itemCounter = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ChartItem>,chartType: null == chartType ? _self.chartType : chartType // ignore: cast_nullable_to_non_nullable
as ChartType,itemCounter: null == itemCounter ? _self.itemCounter : itemCounter // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChartState].
extension ChartStatePatterns on ChartState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChartState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChartState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChartState value)  $default,){
final _that = this;
switch (_that) {
case _ChartState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChartState value)?  $default,){
final _that = this;
switch (_that) {
case _ChartState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ChartItem> items,  ChartType chartType,  int itemCounter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChartState() when $default != null:
return $default(_that.items,_that.chartType,_that.itemCounter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ChartItem> items,  ChartType chartType,  int itemCounter)  $default,) {final _that = this;
switch (_that) {
case _ChartState():
return $default(_that.items,_that.chartType,_that.itemCounter);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ChartItem> items,  ChartType chartType,  int itemCounter)?  $default,) {final _that = this;
switch (_that) {
case _ChartState() when $default != null:
return $default(_that.items,_that.chartType,_that.itemCounter);case _:
  return null;

}
}

}

/// @nodoc


class _ChartState implements ChartState {
  const _ChartState({final  List<ChartItem> items = const [ChartItem(id: 'item1', label: 'Item1', value: 10), ChartItem(id: 'item2', label: 'Item2', value: 20)], this.chartType = ChartType.line, this.itemCounter = 2}): _items = items;
  

/// 入力されたデータ項目のリスト
 final  List<ChartItem> _items;
/// 入力されたデータ項目のリスト
@override@JsonKey() List<ChartItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// 選択されているグラフの種類
@override@JsonKey() final  ChartType chartType;
/// 項目名の連番管理用カウンター（削除されても重複しないように管理）
@override@JsonKey() final  int itemCounter;

/// Create a copy of ChartState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChartStateCopyWith<_ChartState> get copyWith => __$ChartStateCopyWithImpl<_ChartState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChartState&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.chartType, chartType) || other.chartType == chartType)&&(identical(other.itemCounter, itemCounter) || other.itemCounter == itemCounter));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),chartType,itemCounter);

@override
String toString() {
  return 'ChartState(items: $items, chartType: $chartType, itemCounter: $itemCounter)';
}


}

/// @nodoc
abstract mixin class _$ChartStateCopyWith<$Res> implements $ChartStateCopyWith<$Res> {
  factory _$ChartStateCopyWith(_ChartState value, $Res Function(_ChartState) _then) = __$ChartStateCopyWithImpl;
@override @useResult
$Res call({
 List<ChartItem> items, ChartType chartType, int itemCounter
});




}
/// @nodoc
class __$ChartStateCopyWithImpl<$Res>
    implements _$ChartStateCopyWith<$Res> {
  __$ChartStateCopyWithImpl(this._self, this._then);

  final _ChartState _self;
  final $Res Function(_ChartState) _then;

/// Create a copy of ChartState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? chartType = null,Object? itemCounter = null,}) {
  return _then(_ChartState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ChartItem>,chartType: null == chartType ? _self.chartType : chartType // ignore: cast_nullable_to_non_nullable
as ChartType,itemCounter: null == itemCounter ? _self.itemCounter : itemCounter // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
