import 'package:flutter_sample/src/features/map/domain/location_candidate.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_search_state.freezed.dart';

/// 🗺️ 地図検索状態を模した Sealed Class ドメインモデル
@freezed
sealed class MapSearchState with _$MapSearchState {
  /// 初期状態
  const factory MapSearchState.initial() = MapSearchStateInitial;

  /// 検索中
  const factory MapSearchState.loading() = MapSearchStateLoading;

  /// 検索成功 (1件または複数件の候補地リスト)
  const factory MapSearchState.success({
    required List<LocationCandidate> locations,
    required String query,
  }) = MapSearchStateSuccess;

  /// 該当なし
  const factory MapSearchState.empty({
    required String query,
  }) = MapSearchStateEmpty;

  /// 検索エラー
  const factory MapSearchState.error(String message) = MapSearchStateError;
}
