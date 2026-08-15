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

/// Google Routes API を使用したルート計算リポジトリの実装クラス
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
            'X-Goog-Api-Key': _apiKey,
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
