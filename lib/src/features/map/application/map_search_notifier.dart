import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/map/data/geocoding_repository.dart';
import 'package:flutter_sample/src/features/map/data/places_repository.dart';
import 'package:flutter_sample/src/features/map/domain/location_candidate.dart';
import 'package:flutter_sample/src/features/map/domain/map_search_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'map_search_notifier.g.dart';

/// 🗺️ 地図検索状態を管理・更新する Notifier
@riverpod
class MapSearchNotifier extends _$MapSearchNotifier {
  int _requestId = 0;

  @override
  MapSearchState build() {
    _requestId = 0;
    return const MapSearchState.initial();
  }

  /// 指定した住所・キーワードから候補地リストを検索
  /// (Google Places API で複数施設検索 -> 失敗/空時は OS Geocoding に自動フォールバック)
  Future<void> searchLocation(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      _requestId++;
      state = const MapSearchState.initial();
      return;
    }

    final currentRequestId = ++_requestId;
    state = const MapSearchState.loading();

    try {
      var locations = <LocationCandidate>[];

      var isPlacesApiError = false;

      // 1. Google Places API (PlacesRepository) による複数スポット検索
      try {
        final placesRepository = ref.read(placesRepositoryProvider);
        locations = await placesRepository.searchPlaces(trimmedQuery);
      } on Exception catch (placesError, placesSt) {
        isPlacesApiError = true;
        // Places API 通信エラー時はログを記録して Geocoding にフォールバック
        ref
            .read(loggerProvider)
            .handle(
              placesError,
              placesSt,
              'Places API 検索でエラーが発生したため、 '
              'Geocoding にフォールバックします (query: $trimmedQuery)',
            );
      }

      // 2. Places API が空またはエラーだった場合は OS Geocoding にフォールバック
      if (locations.isEmpty) {
        if (!isPlacesApiError) {
          ref
              .read(loggerProvider)
              .info(
                'Places API の検索結果が 0 件だったため、 '
                'Geocoding にフォールバックします (query: $trimmedQuery)',
              );
        }
        final geocodingRepository = ref.read(geocodingRepositoryProvider);
        locations = await geocodingRepository.locationCandidatesFromAddress(
          trimmedQuery,
        );
      }

      if (!ref.mounted || currentRequestId != _requestId) {
        return;
      }

      if (locations.isEmpty) {
        state = MapSearchState.empty(query: trimmedQuery);
      } else {
        state = MapSearchState.success(
          locations: locations,
          query: trimmedQuery,
        );
      }
    } on Exception catch (e, st) {
      if (!ref.mounted || currentRequestId != _requestId) {
        return;
      }
      ref.read(loggerProvider).handle(e, st);
      state = MapSearchState.error(e.toString());
    }
  }

  /// 検索状態をクリア
  void clearSearch() {
    _requestId++;
    state = const MapSearchState.initial();
  }
}
