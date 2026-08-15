import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/domain/travel_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TravelMode Enum Tests', () {
    test('各列挙値の apiValue が Google Routes API 仕様と一致すること', () {
      check(TravelMode.driving.apiValue).equals('DRIVE');
      check(TravelMode.walking.apiValue).equals('WALK');
      check(TravelMode.bicycling.apiValue).equals('BICYCLE');
      check(TravelMode.transit.apiValue).equals('TRANSIT');
    });

    test('values に 4 つの移動手段が含まれていること', () {
      check(TravelMode.values.length).equals(4);
      check(TravelMode.values).contains(TravelMode.driving);
      check(TravelMode.values).contains(TravelMode.walking);
      check(TravelMode.values).contains(TravelMode.bicycling);
      check(TravelMode.values).contains(TravelMode.transit);
    });
  });
}
