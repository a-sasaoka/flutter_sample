import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/features/map/data/polyline_decoder.dart';
import 'package:flutter_sample/src/features/map/domain/map_route.dart';
import 'package:flutter_sample/src/features/map/domain/travel_mode.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_repository.g.dart';

/// ルート計算リポジトリのインターフェース
// ignore: one_member_abstracts, リポジトリ層の単一責務インターフェースのため
abstract interface class RouteRepository {
  /// 出発地と目的地から経路を計算する
  Future<MapRoute> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    String? destinationName,
    TravelMode travelMode = TravelMode.driving,
  });
}

/// Google Routes API / プロキシサーバーを使用したルート計算リポジトリの実装クラス
class RouteRepositoryImpl implements RouteRepository {
  /// コンストラクタ
  const RouteRepositoryImpl({
    required Dio dio,
    String directionsApiUrl = defaultGoogleDirectionsApiUrl,
  }) : _dio = dio,
       _directionsApiUrl = directionsApiUrl;

  final Dio _dio;
  final String _directionsApiUrl;

  @override
  Future<MapRoute> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    String? destinationName,
    TravelMode travelMode = TravelMode.driving,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _directionsApiUrl,
        data: {
          'origin': {
            'location': {
              'latLng': {
                'latitude': origin.latitude,
                'longitude': origin.longitude,
              },
            },
          },
          'destination': {
            'location': {
              'latLng': {
                'latitude': destination.latitude,
                'longitude': destination.longitude,
              },
            },
          },
          'travelMode': travelMode.apiValue,
        },
        options: Options(
          headers: {
            'X-Goog-FieldMask':
                'routes.duration,routes.distanceMeters,'
                'routes.polyline.encodedPolyline,routes.warnings',
          },
        ),
      );

      final data = response.data;
      if (data == null) {
        throw const RouteApiException('Route response data is empty.');
      }

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        throw const RouteApiException('No route found in response.');
      }

      final firstRoute = routes.first as Map<String, dynamic>;
      final polylineMap = firstRoute['polyline'] as Map<String, dynamic>?;
      final encodedPoints = polylineMap?['encodedPolyline'] as String? ?? '';
      final points = decodePolyline(encodedPoints);

      final distanceMeters =
          (firstRoute['distanceMeters'] as num?)?.toDouble() ?? 0.0;
      final durationRaw = firstRoute['duration'];
      final durationSeconds = _parseDurationSeconds(durationRaw);

      final rawWarnings = firstRoute['warnings'] as List<dynamic>?;
      final warnings =
          rawWarnings?.map((e) => e.toString()).toList() ?? const <String>[];

      final id =
          'route_${origin.latitude}_${origin.longitude}_'
          '${destination.latitude}_${destination.longitude}_'
          '${travelMode.apiValue}';

      return MapRoute(
        id: id,
        origin: origin,
        destination: destination,
        points: points.isNotEmpty ? points : [origin, destination],
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        destinationName: destinationName,
        travelMode: travelMode,
        warnings: warnings,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        final errorMap = responseData['error'] as Map<String, dynamic>?;
        final message = errorMap?['message'] as String?;
        if (message != null && message.isNotEmpty) {
          throw RouteApiException(message);
        }
      }
      throw RouteApiException(e.message ?? 'Failed to calculate route.');
    }
  }

  /// 秒数表記（例: "480s" や 480）から秒数を整数で抽出する
  int _parseDurationSeconds(dynamic duration) {
    if (duration is num) {
      return duration.toInt();
    }
    if (duration is String) {
      final sanitized = duration.endsWith('s')
          ? duration.substring(0, duration.length - 1)
          : duration;
      return double.tryParse(sanitized)?.toInt() ?? 0;
    }
    return 0;
  }
}

/// ローカル開発環境やオフラインテスト用のモック RouteRepository 実装クラス
class MockRouteRepository implements RouteRepository {
  /// コンストラクタ
  const MockRouteRepository();

  @override
  Future<MapRoute> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    String? destinationName,
    TravelMode travelMode = TravelMode.driving,
  }) async {
    // 擬似的な非同期通信遅延（100ms）
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // 2点間の直線距離（km）を簡易計算
    final latDiff = (destination.latitude - origin.latitude).abs();
    final lngDiff = (destination.longitude - origin.longitude).abs();
    final distanceKm = ((latDiff * 111.0) + (lngDiff * 91.0)).clamp(0.5, 100.0);
    final distanceMeters = distanceKm * 1000;

    // 移動手段ごとの想定平均速度 (km/h) から所要時間 (秒) を算出
    final speedKmh = switch (travelMode) {
      TravelMode.driving => 40.0,
      TravelMode.walking => 4.8,
      TravelMode.bicycling => 15.0,
      TravelMode.transit => 30.0,
    };
    final durationSeconds = ((distanceKm / speedKmh) * 3600).ceil();

    // 出発地から目的地までの補間折れ線座標（5点）を生成
    final points = <LatLng>[
      origin,
      LatLng(
        origin.latitude +
            (destination.latitude - origin.latitude) * 0.25 +
            0.0005,
        origin.longitude +
            (destination.longitude - origin.longitude) * 0.25 -
            0.0005,
      ),
      LatLng(
        origin.latitude +
            (destination.latitude - origin.latitude) * 0.5 -
            0.0005,
        origin.longitude +
            (destination.longitude - origin.longitude) * 0.5 +
            0.0005,
      ),
      LatLng(
        origin.latitude +
            (destination.latitude - origin.latitude) * 0.75 +
            0.0003,
        origin.longitude +
            (destination.longitude - origin.longitude) * 0.75 -
            0.0003,
      ),
      destination,
    ];

    final id =
        'mock_route_${origin.latitude}_${origin.longitude}_'
        '${destination.latitude}_${destination.longitude}_'
        '${travelMode.apiValue}';

    return MapRoute(
      id: id,
      origin: origin,
      destination: destination,
      points: points,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      destinationName: destinationName ?? 'モック目的地',
      travelMode: travelMode,
    );
  }
}

/// ルートAPI呼び出し時の例外クラス
class RouteApiException implements Exception {
  /// コンストラクタ
  const RouteApiException(this.message);

  /// エラーメッセージ
  final String message;

  @override
  String toString() => message;
}

/// RouteRepository を提供する Riverpod プロバイダー
@Riverpod(keepAlive: true)
RouteRepository routeRepository(Ref ref) {
  final flavor = ref.watch(flavorProvider);
  if (flavor == Flavor.local) {
    return const MockRouteRepository();
  }
  final dio = ref.watch(baseDioProvider);
  final envConfig = ref.watch(envConfigProvider);
  return RouteRepositoryImpl(
    dio: dio,
    directionsApiUrl: envConfig.googleDirectionsApiUrl,
  );
}
