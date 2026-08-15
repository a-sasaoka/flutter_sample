import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/map/data/route_repository.dart';
import 'package:flutter_sample/src/features/map/domain/map_route_state.dart';
import 'package:flutter_sample/src/features/map/domain/travel_mode.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'map_route_notifier.g.dart';

/// ルート検索および案内状態を管理する Notifier
@riverpod
class MapRouteNotifier extends _$MapRouteNotifier {
  /// 検索リクエストの世代番号（競合・古い結果の上書きを防止）
  int _searchGeneration = 0;

  @override
  MapRouteState build() {
    return const MapRouteState.initial();
  }

  /// 2点間のルートを検索・計算して状態を更新する
  Future<void> searchRoute({
    required LatLng origin,
    required LatLng destination,
    String? destinationName,
    TravelMode travelMode = TravelMode.driving,
  }) async {
    final searchGeneration = ++_searchGeneration;
    state = const MapRouteState.loading();

    try {
      final repository = ref.read(routeRepositoryProvider);
      final route = await repository.calculateRoute(
        origin: origin,
        destination: destination,
        destinationName: destinationName,
        travelMode: travelMode,
      );

      if (!ref.mounted || searchGeneration != _searchGeneration) return;
      state = MapRouteState.success(route);
    } on Exception catch (e, st) {
      if (!ref.mounted || searchGeneration != _searchGeneration) return;
      ref.read(loggerProvider).handle(e, st);
      state = MapRouteState.error(e.toString());
    }
  }

  /// ルート案内をクリア・終了する
  void clearRoute() {
    _searchGeneration++;
    state = const MapRouteState.initial();
  }
}
