import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/domain/map_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapConstants Tests', () {
    test('定数の値が正しく定義されていること', () {
      check(MapConstants.googleMapsHost).equals('www.google.com');
      check(MapConstants.googleMapsDirectionsPath).equals('/maps/dir/');
      check(MapConstants.googleMapsApiVersion).equals('1');
      check(MapConstants.googleMapsParamApi).equals('api');
      check(MapConstants.googleMapsParamOrigin).equals('origin');
      check(MapConstants.googleMapsParamDestination).equals('destination');
      check(MapConstants.googleMapsParamTravelMode).equals('travelmode');
      check(MapConstants.googleMapsTravelModeTransit).equals('transit');
    });
  });
}
