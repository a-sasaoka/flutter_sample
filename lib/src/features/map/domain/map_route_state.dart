import 'package:flutter_sample/src/features/map/domain/map_route.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_route_state.freezed.dart';

/// ルート検索・案内状態を表す Sealed クラス
@freezed
sealed class MapRouteState with _$MapRouteState {
  /// 初期状態 (ルート未検索)
  const factory MapRouteState.initial() = MapRouteStateInitial;

  /// ルート検索・計算中
  const factory MapRouteState.loading() = MapRouteStateLoading;

  /// ルート検索成功 (案内中)
  const factory MapRouteState.success(MapRoute route) = MapRouteStateSuccess;

  /// ルート検索エラー
  const factory MapRouteState.error(String message) = MapRouteStateError;
}
