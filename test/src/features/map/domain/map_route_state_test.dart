import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/domain/map_route.dart';
import 'package:flutter_sample/src/features/map/domain/map_route_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('MapRouteState Tests', () {
    test('initial 状態を正常にインスタンス化できること', () {
      const state = MapRouteState.initial();
      check(state).isA<MapRouteState>();
    });

    test('loading 状態を正常にインスタンス化できること', () {
      const state = MapRouteState.loading();
      check(state).isA<MapRouteState>();
    });

    test('success 状態を正常にインスタンス化できること', () {
      const route = MapRoute(
        id: 'route_1',
        origin: LatLng(35, 139),
        destination: LatLng(35.1, 139.1),
        points: [LatLng(35, 139), LatLng(35.1, 139.1)],
        distanceMeters: 5000,
        durationSeconds: 300,
      );
      const state = MapRouteState.success(route);
      check(state).isA<MapRouteState>();
    });

    test('error 状態を正常にインスタンス化できること', () {
      const state = MapRouteState.error('エラーメッセージ');
      check(state).isA<MapRouteState>();
    });
  });
}
