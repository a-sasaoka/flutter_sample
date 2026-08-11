import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geocoding/geocoding.dart';

part 'map_search_state.freezed.dart';

/// 🗺️ 住所・ランドマーク検索状態を表す Sealed Class
@freezed
sealed class MapSearchState with _$MapSearchState {
  /// 初期状態 (未検索)
  const factory MapSearchState.initial() = MapSearchStateInitial;

  /// 検索処理中
  const factory MapSearchState.loading() = MapSearchStateLoading;

  /// 検索成功 (該当位置情報のリストと検索クエリ)
  const factory MapSearchState.success({
    required List<Location> locations,
    required String query,
  }) = MapSearchStateSuccess;

  /// 該当結果なし
  const factory MapSearchState.empty({
    required String query,
  }) = MapSearchStateEmpty;

  /// 検索エラー発生
  const factory MapSearchState.error(String message) = MapSearchStateError;
}
