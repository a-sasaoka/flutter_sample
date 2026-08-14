import 'package:flutter_sample/src/features/map/domain/travel_mode.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'map_route.freezed.dart';

/// 2点間のルート情報を表すドメインモデル
@freezed
abstract class MapRoute with _$MapRoute {
  /// MapRoute のファクトリコンストラクタ
  const factory MapRoute({
    /// ルートの固有ID
    required String id,

    /// 出発地座標
    required LatLng origin,

    /// 目的地座標
    required LatLng destination,

    /// 経路を構成する緯度経度座標リスト (Polyline用)
    required List<LatLng> points,

    /// 総移動距離 (メートル単位)
    required double distanceMeters,

    /// 総予想所要時間 (秒単位)
    required int durationSeconds,

    /// 目的地の名称 (スポット名や住所など)
    String? destinationName,

    /// 移動手段の種別 (車、徒歩、自転車、公共交通機関)
    @Default(TravelMode.driving) TravelMode travelMode,
  }) = _MapRoute;

  /// MapRoute のカスタムゲッター用プライベートコンストラクタ
  const MapRoute._();

  /// キロメートル単位の距離文字列 (例: "3.5")
  String get distanceKm => (distanceMeters / 1000).toStringAsFixed(1);

  /// 分単位の所要時間 (切り上げ)
  int get durationMinutes => (durationSeconds / 60).ceil();

  /// 経路全体を包含する LatLngBounds (カメラ自動調整用)
  LatLngBounds get bounds {
    final allPoints = points.isEmpty ? [origin, destination] : points;

    var minLat = allPoints.first.latitude;
    var maxLat = allPoints.first.latitude;
    var minLng = allPoints.first.longitude;
    var maxLng = allPoints.first.longitude;

    for (final point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
