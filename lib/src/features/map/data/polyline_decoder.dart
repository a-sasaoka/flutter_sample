import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Google Encoded Polyline Algorithm 形式の文字列を [LatLng] のリストへデコードするユーティリティ関数
///
/// Google Directions API などから返却される圧縮されたポリライン文字列を、
/// 地図上に描画可能な座標配列へ変換します。
List<LatLng> decodePolyline(String encoded) {
  if (encoded.isEmpty) {
    return const [];
  }

  final poly = <LatLng>[];
  var index = 0;
  final len = encoded.length;
  var lat = 0;
  var lng = 0;

  while (index < len) {
    var b = 0;
    var shift = 0;
    var result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);

    final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);

    final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    poly.add(LatLng(lat / 1e5, lng / 1e5));
  }

  return poly;
}
