import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/map/data/geocoding_repository.dart';
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
      final repository = ref.read(geocodingRepositoryProvider);
      final locations = await repository.locationCandidatesFromAddress(
        trimmedQuery,
      );

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
