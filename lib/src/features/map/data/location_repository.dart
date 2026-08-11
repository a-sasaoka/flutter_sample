import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_repository.g.dart';

/// 🗺️ Geolocator ネイティブAPIを安全にラップする LocationRepository
class LocationRepository {
  /// コンストラクタ（テスト時にモック GeolocatorPlatform を注入可能）
  LocationRepository({GeolocatorPlatform? geolocator})
    : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _geolocator;

  /// GPS位置情報サービスが端末で有効かどうかを確認
  Future<bool> isLocationServiceEnabled() async {
    return _geolocator.isLocationServiceEnabled();
  }

  /// 位置情報パーミッション状態を確認
  Future<LocationPermission> checkPermission() async {
    return _geolocator.checkPermission();
  }

  /// 位置情報パーミッションを要求
  Future<LocationPermission> requestPermission() async {
    return _geolocator.requestPermission();
  }

  /// 現在地 (Position) を取得
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    return _geolocator.getCurrentPosition(
      locationSettings:
          locationSettings ??
          const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
    );
  }

  /// 端末の設定画面を開く
  Future<bool> openAppSettings() async {
    return _geolocator.openAppSettings();
  }

  /// 端末の位置情報設定画面を開く
  Future<bool> openLocationSettings() async {
    return _geolocator.openLocationSettings();
  }
}

/// LocationRepository のプロバイダー定義（単なるDartクラスのため関数プロバイダとして定義）
@Riverpod(keepAlive: true)
LocationRepository locationRepository(Ref ref) {
  return LocationRepository();
}
