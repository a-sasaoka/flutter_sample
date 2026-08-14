import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
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

/// Google Directions API を使用したルート計算リポジトリの実装クラス
class RouteRepositoryImpl implements RouteRepository {
  /// コンストラクタ
  const RouteRepositoryImpl({
    required Dio dio,
    required String apiKey,
    String directionsApiUrl = defaultGoogleDirectionsApiUrl,
  }) : _dio = dio,
       _apiKey = apiKey,
       _directionsApiUrl = directionsApiUrl;

  final Dio _dio;
  final String _apiKey;
  final String _directionsApiUrl;

  @override
  Future<MapRoute> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    String? destinationName,
    TravelMode travelMode = TravelMode.driving,
  }) async {
    if (_apiKey.isEmpty) {
      throw const RouteApiException(
        'Google Maps API key is not configured. '
        'Please set MAPS_API_KEY in .env file.',
      );
    }

    final response = await _dio.get<Map<String, dynamic>>(
      _directionsApiUrl,
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': travelMode.apiValue,
        'key': _apiKey,
      },
    );

    final data = response.data;
    if (data == null) {
      throw const RouteApiException('Route response data is empty.');
    }

    final status = data['status'] as String?;
    if (status != 'OK') {
      final errorMessage =
          data['error_message'] as String? ?? 'Failed to find route ($status).';
      throw RouteApiException(errorMessage);
    }

    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw const RouteApiException('No route found in response.');
    }

    final firstRoute = routes.first as Map<String, dynamic>;
    final overviewPolyline =
        firstRoute['overview_polyline'] as Map<String, dynamic>?;
    final encodedPoints = overviewPolyline?['points'] as String? ?? '';
    final points = decodePolyline(encodedPoints);

    final legs = firstRoute['legs'] as List<dynamic>?;
    final firstLeg = (legs != null && legs.isNotEmpty)
        ? legs.first as Map<String, dynamic>
        : null;

    final distanceMap = firstLeg?['distance'] as Map<String, dynamic>?;
    final distanceMeters = (distanceMap?['value'] as num?)?.toDouble() ?? 0.0;

    final durationMap = firstLeg?['duration'] as Map<String, dynamic>?;
    final durationSeconds = (durationMap?['value'] as num?)?.toInt() ?? 0;

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
  final dio = ref.watch(baseDioProvider);
  final envConfig = ref.watch(envConfigProvider);
  return RouteRepositoryImpl(
    dio: dio,
    apiKey: AppEnv.mapsApiKey,
    directionsApiUrl: envConfig.googleDirectionsApiUrl,
  );
}
