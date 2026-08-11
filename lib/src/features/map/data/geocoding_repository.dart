import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geocoding_repository.g.dart';

/// 🗺️ Geocoding (住所・キーワードからの座標変換) を安全に行う Repository
class GeocodingRepository {
  /// コンストラクタ（テスト時に Geocoding インスタンスを注入可能）
  GeocodingRepository({Geocoding? geocoding}) : _geocoding = geocoding;

  final Geocoding? _geocoding;

  /// 住所やランドマークのキーワード文字列から緯度経度のリストを取得
  Future<List<Location>> locationFromAddressQuery(
    String address, {
    Locale? locale,
  }) async {
    final geocoding = _geocoding ?? Geocoding();
    return geocoding.locationFromAddress(
      address,
      locale: locale,
    );
  }
}

/// GeocodingRepository のプロバイダー定義（単なるDartクラスのため関数プロバイダとして定義）
@Riverpod(keepAlive: true)
GeocodingRepository geocodingRepository(Ref ref) {
  return GeocodingRepository();
}
