import 'package:flutter/widgets.dart';
import 'package:flutter_sample/src/features/map/domain/location_candidate.dart';
import 'package:geocoding/geocoding.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geocoding_repository.g.dart';

/// 🗺️ Geocoding (住所・キーワードからの座標変換・住所取得) を安全に行う Repository
class GeocodingRepository {
  /// コンストラクタ（テスト時に Geocoding インスタンスやテスト用ハンドラを注入可能）
  GeocodingRepository({
    Geocoding? geocoding,
    Future<List<LocationCandidate>> Function(
      String address, {
      Locale? locale,
    })?
    candidatesHandler,
  }) : _geocoding = geocoding,
       _candidatesHandler = candidatesHandler;

  final Geocoding? _geocoding;
  final Future<List<LocationCandidate>> Function(
    String address, {
    Locale? locale,
  })?
  _candidatesHandler;

  /// 住所やランドマークのキーワード文字列から候補地 (LocationCandidate) のリストを取得
  Future<List<LocationCandidate>> locationCandidatesFromAddress(
    String address, {
    Locale? locale,
  }) async {
    if (_candidatesHandler != null) {
      return _candidatesHandler(address, locale: locale);
    }

    final geocoding = _geocoding ?? Geocoding();
    final locations = await geocoding.locationFromAddress(
      address,
      locale: locale,
    );

    final candidates = <LocationCandidate>[];
    for (final loc in locations) {
      String? name;
      String? addressString;

      try {
        final placemarks = await geocoding.placemarkFromCoordinates(
          loc.latitude,
          loc.longitude,
          locale: locale,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final nameParts = <String>[
            if (p.name != null && p.name!.isNotEmpty) p.name!,
            if (p.street != null && p.street!.isNotEmpty && p.street != p.name)
              p.street!,
          ];
          name = nameParts.isNotEmpty ? nameParts.join(' ') : address;

          final addressParts = <String>[
            if (p.administrativeArea != null) p.administrativeArea!,
            if (p.locality != null) p.locality!,
            if (p.subLocality != null) p.subLocality!,
            if (p.thoroughfare != null && p.thoroughfare != p.subLocality)
              p.thoroughfare!,
          ];
          if (addressParts.isNotEmpty) {
            addressString = addressParts.join();
          }
        }
      } on Exception {
        // 逆ジオコーディング失敗時はフォールバック表示
      }

      candidates.add(
        LocationCandidate(
          latitude: loc.latitude,
          longitude: loc.longitude,
          name: name ?? address,
          address: addressString,
        ),
      );
    }

    return candidates;
  }
}

/// GeocodingRepository のプロバイダー定義（単なるDartクラスのため関数プロバイダとして定義）
@Riverpod(keepAlive: true)
GeocodingRepository geocodingRepository(Ref ref) {
  return GeocodingRepository();
}
