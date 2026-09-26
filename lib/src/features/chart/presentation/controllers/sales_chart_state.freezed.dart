// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sales_chart_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SalesChartState {

/// 選択中の表示期間
 SalesPeriod get period;/// グラフ描画用の座標リスト
 List<FlSpot> get spots;/// X軸に表示する日付ラベルリスト
 List<String> get dateLabels;/// Y軸の最大値（見切れ防止マージン込み）
 double get maxY;/// 選択期間の合計売上
 int get totalSales;/// 選択期間の日別平均売上
 int get dailyAverage;
/// Create a copy of SalesChartState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SalesChartStateCopyWith<SalesChartState> get copyWith => _$SalesChartStateCopyWithImpl<SalesChartState>(this as SalesChartState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesChartState&&(identical(other.period, period) || other.period == period)&&const DeepCollectionEquality().equals(other.spots, spots)&&const DeepCollectionEquality().equals(other.dateLabels, dateLabels)&&(identical(other.maxY, maxY) || other.maxY == maxY)&&(identical(other.totalSales, totalSales) || other.totalSales == totalSales)&&(identical(other.dailyAverage, dailyAverage) || other.dailyAverage == dailyAverage));
}


@override
int get hashCode => Object.hash(runtimeType,period,const DeepCollectionEquality().hash(spots),const DeepCollectionEquality().hash(dateLabels),maxY,totalSales,dailyAverage);

@override
String toString() {
  return 'SalesChartState(period: $period, spots: $spots, dateLabels: $dateLabels, maxY: $maxY, totalSales: $totalSales, dailyAverage: $dailyAverage)';
}


}

/// @nodoc
abstract mixin class $SalesChartStateCopyWith<$Res>  {
  factory $SalesChartStateCopyWith(SalesChartState value, $Res Function(SalesChartState) _then) = _$SalesChartStateCopyWithImpl;
@useResult
$Res call({
 SalesPeriod period, List<FlSpot> spots, List<String> dateLabels, double maxY, int totalSales, int dailyAverage
});




}
/// @nodoc
class _$SalesChartStateCopyWithImpl<$Res>
    implements $SalesChartStateCopyWith<$Res> {
  _$SalesChartStateCopyWithImpl(this._self, this._then);

  final SalesChartState _self;
  final $Res Function(SalesChartState) _then;

/// Create a copy of SalesChartState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? spots = null,Object? dateLabels = null,Object? maxY = null,Object? totalSales = null,Object? dailyAverage = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as SalesPeriod,spots: null == spots ? _self.spots : spots // ignore: cast_nullable_to_non_nullable
as List<FlSpot>,dateLabels: null == dateLabels ? _self.dateLabels : dateLabels // ignore: cast_nullable_to_non_nullable
as List<String>,maxY: null == maxY ? _self.maxY : maxY // ignore: cast_nullable_to_non_nullable
as double,totalSales: null == totalSales ? _self.totalSales : totalSales // ignore: cast_nullable_to_non_nullable
as int,dailyAverage: null == dailyAverage ? _self.dailyAverage : dailyAverage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SalesChartState].
extension SalesChartStatePatterns on SalesChartState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SalesChartState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SalesChartState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SalesChartState value)  $default,){
final _that = this;
switch (_that) {
case _SalesChartState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SalesChartState value)?  $default,){
final _that = this;
switch (_that) {
case _SalesChartState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SalesPeriod period,  List<FlSpot> spots,  List<String> dateLabels,  double maxY,  int totalSales,  int dailyAverage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SalesChartState() when $default != null:
return $default(_that.period,_that.spots,_that.dateLabels,_that.maxY,_that.totalSales,_that.dailyAverage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SalesPeriod period,  List<FlSpot> spots,  List<String> dateLabels,  double maxY,  int totalSales,  int dailyAverage)  $default,) {final _that = this;
switch (_that) {
case _SalesChartState():
return $default(_that.period,_that.spots,_that.dateLabels,_that.maxY,_that.totalSales,_that.dailyAverage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SalesPeriod period,  List<FlSpot> spots,  List<String> dateLabels,  double maxY,  int totalSales,  int dailyAverage)?  $default,) {final _that = this;
switch (_that) {
case _SalesChartState() when $default != null:
return $default(_that.period,_that.spots,_that.dateLabels,_that.maxY,_that.totalSales,_that.dailyAverage);case _:
  return null;

}
}

}

/// @nodoc


class _SalesChartState implements SalesChartState {
  const _SalesChartState({required this.period, required final  List<FlSpot> spots, required final  List<String> dateLabels, required this.maxY, required this.totalSales, required this.dailyAverage}): _spots = spots,_dateLabels = dateLabels;
  

/// 選択中の表示期間
@override final  SalesPeriod period;
/// グラフ描画用の座標リスト
 final  List<FlSpot> _spots;
/// グラフ描画用の座標リスト
@override List<FlSpot> get spots {
  if (_spots is EqualUnmodifiableListView) return _spots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_spots);
}

/// X軸に表示する日付ラベルリスト
 final  List<String> _dateLabels;
/// X軸に表示する日付ラベルリスト
@override List<String> get dateLabels {
  if (_dateLabels is EqualUnmodifiableListView) return _dateLabels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dateLabels);
}

/// Y軸の最大値（見切れ防止マージン込み）
@override final  double maxY;
/// 選択期間の合計売上
@override final  int totalSales;
/// 選択期間の日別平均売上
@override final  int dailyAverage;

/// Create a copy of SalesChartState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SalesChartStateCopyWith<_SalesChartState> get copyWith => __$SalesChartStateCopyWithImpl<_SalesChartState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SalesChartState&&(identical(other.period, period) || other.period == period)&&const DeepCollectionEquality().equals(other._spots, _spots)&&const DeepCollectionEquality().equals(other._dateLabels, _dateLabels)&&(identical(other.maxY, maxY) || other.maxY == maxY)&&(identical(other.totalSales, totalSales) || other.totalSales == totalSales)&&(identical(other.dailyAverage, dailyAverage) || other.dailyAverage == dailyAverage));
}


@override
int get hashCode => Object.hash(runtimeType,period,const DeepCollectionEquality().hash(_spots),const DeepCollectionEquality().hash(_dateLabels),maxY,totalSales,dailyAverage);

@override
String toString() {
  return 'SalesChartState(period: $period, spots: $spots, dateLabels: $dateLabels, maxY: $maxY, totalSales: $totalSales, dailyAverage: $dailyAverage)';
}


}

/// @nodoc
abstract mixin class _$SalesChartStateCopyWith<$Res> implements $SalesChartStateCopyWith<$Res> {
  factory _$SalesChartStateCopyWith(_SalesChartState value, $Res Function(_SalesChartState) _then) = __$SalesChartStateCopyWithImpl;
@override @useResult
$Res call({
 SalesPeriod period, List<FlSpot> spots, List<String> dateLabels, double maxY, int totalSales, int dailyAverage
});




}
/// @nodoc
class __$SalesChartStateCopyWithImpl<$Res>
    implements _$SalesChartStateCopyWith<$Res> {
  __$SalesChartStateCopyWithImpl(this._self, this._then);

  final _SalesChartState _self;
  final $Res Function(_SalesChartState) _then;

/// Create a copy of SalesChartState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? spots = null,Object? dateLabels = null,Object? maxY = null,Object? totalSales = null,Object? dailyAverage = null,}) {
  return _then(_SalesChartState(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as SalesPeriod,spots: null == spots ? _self._spots : spots // ignore: cast_nullable_to_non_nullable
as List<FlSpot>,dateLabels: null == dateLabels ? _self._dateLabels : dateLabels // ignore: cast_nullable_to_non_nullable
as List<String>,maxY: null == maxY ? _self.maxY : maxY // ignore: cast_nullable_to_non_nullable
as double,totalSales: null == totalSales ? _self.totalSales : totalSales // ignore: cast_nullable_to_non_nullable
as int,dailyAverage: null == dailyAverage ? _self.dailyAverage : dailyAverage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
