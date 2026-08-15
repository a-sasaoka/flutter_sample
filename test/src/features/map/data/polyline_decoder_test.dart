import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/data/polyline_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PolylineDecoder Tests', () {
    test('空文字列を渡した場合は空のリストを返すこと', () {
      final points = decodePolyline('');
      check(points).isEmpty();
    });

    test('Google 公式のエンコード文字列が正しい LatLng リストにデコードされること', () {
      // Google Directions API 公式ドキュメントのサンプルエンコード
      // points: (38.5, -120.2), (40.7, -120.95), (43.252, -126.453)
      const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      final points = decodePolyline(encoded);

      check(points.length).equals(3);

      check(points[0].latitude).isCloseTo(38.5, 0.0001);
      check(points[0].longitude).isCloseTo(-120.2, 0.0001);

      check(points[1].latitude).isCloseTo(40.7, 0.0001);
      check(points[1].longitude).isCloseTo(-120.95, 0.0001);

      check(points[2].latitude).isCloseTo(43.252, 0.0001);
      check(points[2].longitude).isCloseTo(-126.453, 0.0001);
    });

    test('単一座標のエンコード文字列が正しくデコードされること', () {
      // (38.5, -120.2)
      const encoded = '_p~iF~ps|U';
      final points = decodePolyline(encoded);

      check(points.length).equals(1);
      check(points[0].latitude).isCloseTo(38.5, 0.0001);
      check(points[0].longitude).isCloseTo(-120.2, 0.0001);
    });
  });
}
