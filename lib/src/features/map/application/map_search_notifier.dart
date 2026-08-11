import 'package:flutter_sample/src/features/map/data/geocoding_repository.dart';
import 'package:flutter_sample/src/features/map/domain/map_search_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'map_search_notifier.g.dart';

/// 🗺️ 地図検索状態を管理・更新する Notifier
@riverpod
class MapSearchNotifier extends _$MapSearchNotifier {
  @override
  MapSearchState build() {
    return const MapSearchState.initial();
  }

  /// 指定した住所・キーワードから緯度経度座標を検索
  Future<void> searchLocation(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      state = const MapSearchState.initial();
      return;
    }

    state = const MapSearchState.loading();

    try {
      final repository = ref.read(geocodingRepositoryProvider);
      final locations = await repository.locationFromAddressQuery(trimmedQuery);

      if (locations.isEmpty) {
        state = MapSearchState.empty(query: trimmedQuery);
      } else {
        state = MapSearchState.success(
          locations: locations,
          query: trimmedQuery,
        );
      }
    } on Exception catch (e) {
      state = MapSearchState.error(e.toString());
    }
  }

  /// 検索状態をクリア
  void clearSearch() {
    state = const MapSearchState.initial();
  }
}
