import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/domain/map_route.dart';
import 'package:flutter_sample/src/features/map/domain/travel_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('MapRoute Domain Tests', () {
    test('MapRoute の各ゲッターが期待値を返すこと', () {
      const origin = LatLng(35.681236, 139.767125);
      const destination = LatLng(35.6585805, 139.7454329);
      final points = [
        origin,
        const LatLng(35.670, 139.755),
        destination,
      ];

      final route = MapRoute(
        id: 'test_route_1',
        origin: origin,
        destination: destination,
        points: points,
        distanceMeters: 3540,
        durationSeconds: 360,
        destinationName: '東京タワー',
      );

      check(route.id).equals('test_route_1');
      check(route.distanceKm).equals('3.5');
      check(route.durationMinutes).equals(6);
      check(route.destinationName).equals('東京タワー');
      check(route.travelMode).equals(TravelMode.driving);

      final bounds = route.bounds;
      check(bounds.southwest.latitude).equals(35.6585805);
      check(bounds.southwest.longitude).equals(139.7454329);
      check(bounds.northeast.latitude).equals(35.681236);
      check(bounds.northeast.longitude).equals(139.767125);
    });

    test('カスタム travelMode を指定して正常に生成できること', () {
      const origin = LatLng(35.681236, 139.767125);
      const destination = LatLng(35.6585805, 139.7454329);

      const route = MapRoute(
        id: 'test_route_walking',
        origin: origin,
        destination: destination,
        points: [origin, destination],
        distanceMeters: 3000,
        durationSeconds: 2400,
        travelMode: TravelMode.walking,
      );

      check(route.travelMode).equals(TravelMode.walking);
      check(route.durationMinutes).equals(40);
    });

    test('points が空の場合でも origin と destination から bounds が算出されること', () {
      const origin = LatLng(35.681236, 139.767125);
      const destination = LatLng(35.6585805, 139.7454329);

      const route = MapRoute(
        id: 'test_route_empty_points',
        origin: origin,
        destination: destination,
        points: [],
        distanceMeters: 1000,
        durationSeconds: 120,
      );

      final bounds = route.bounds;
      check(bounds.southwest.latitude).equals(35.6585805);
      check(bounds.southwest.longitude).equals(139.7454329);
      check(bounds.northeast.latitude).equals(35.681236);
      check(bounds.northeast.longitude).equals(139.767125);
    });
  });
}
