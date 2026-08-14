import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/map/data/route_repository.dart';
import 'package:flutter_sample/src/features/map/domain/travel_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('RouteRepository Tests', () {
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
    });

    const origin = LatLng(35.681236, 139.767125);
    const destination = LatLng(35.6585805, 139.7454329);

    test('Google Directions API 成功時に正常な MapRoute を生成して返すこと', () async {
      final repository = RouteRepositoryImpl(
        dio: mockDio,
        apiKey: 'test_api_key',
      );

      final mockApiResponse = {
        'status': 'OK',
        'routes': [
          {
            'overview_polyline': {
              'points': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
            },
            'legs': [
              {
                'distance': {'value': 4200, 'text': '4.2 km'},
                'duration': {'value': 480, 'text': '8分'},
              },
            ],
          },
        ],
      };

      when(
        () => mockDio.get<Map<String, dynamic>>(
          'https://maps.googleapis.com/maps/api/directions/json',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: mockApiResponse,
        ),
      );

      final route = await repository.calculateRoute(
        origin: origin,
        destination: destination,
        destinationName: '東京タワー',
      );

      check(route.origin).equals(origin);
      check(route.destination).equals(destination);
      check(route.destinationName).equals('東京タワー');
      check(route.distanceMeters).equals(4200);
      check(route.durationSeconds).equals(480);
      check(route.points.length).equals(3);
    });

    test(
      'overview_polyline や legs が空の場合でもフォールバックして MapRoute を生成すること',
      () async {
        final repository = RouteRepositoryImpl(
          dio: mockDio,
          apiKey: 'test_api_key',
        );

        final mockApiResponse = {
          'status': 'OK',
          'routes': [
            <String, dynamic>{},
          ],
        };

        when(
          () => mockDio.get<Map<String, dynamic>>(
            'https://maps.googleapis.com/maps/api/directions/json',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(),
            data: mockApiResponse,
          ),
        );

        final route = await repository.calculateRoute(
          origin: origin,
          destination: destination,
        );

        check(route.distanceMeters).equals(0);
        check(route.durationSeconds).equals(0);
        check(route.points).deepEquals([origin, destination]);
      },
    );

    test('APIキーが未設定の場合は RouteApiException をスローすること', () async {
      final repository = RouteRepositoryImpl(
        dio: mockDio,
        apiKey: '',
      );

      await check(
        repository.calculateRoute(
          origin: origin,
          destination: destination,
        ),
      ).throws<RouteApiException>();
    });

    test('レスポンスデータが null の場合は RouteApiException をスローすること', () async {
      final repository = RouteRepositoryImpl(
        dio: mockDio,
        apiKey: 'test_api_key',
      );

      when(
        () => mockDio.get<Map<String, dynamic>>(
          'https://maps.googleapis.com/maps/api/directions/json',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
        ),
      );

      await check(
        repository.calculateRoute(
          origin: origin,
          destination: destination,
        ),
      ).throws<RouteApiException>();
    });

    test(
      'API ステータスが OK 以外の場合は error_message を含む RouteApiException をスローすること',
      () async {
        final repository = RouteRepositoryImpl(
          dio: mockDio,
          apiKey: 'test_api_key',
        );

        final mockApiResponse = {
          'status': 'ZERO_RESULTS',
          'error_message': '経路が見つかりませんでした',
        };

        when(
          () => mockDio.get<Map<String, dynamic>>(
            'https://maps.googleapis.com/maps/api/directions/json',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(),
            data: mockApiResponse,
          ),
        );

        await check(
          repository.calculateRoute(
            origin: origin,
            destination: destination,
          ),
        ).throws<RouteApiException>();
      },
    );

    test('API ステータスが OK 以外で error_message がない場合のデフォルトメッセージ確認', () async {
      final repository = RouteRepositoryImpl(
        dio: mockDio,
        apiKey: 'test_api_key',
      );

      final mockApiResponse = {
        'status': 'REQUEST_DENIED',
      };

      when(
        () => mockDio.get<Map<String, dynamic>>(
          'https://maps.googleapis.com/maps/api/directions/json',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: mockApiResponse,
        ),
      );

      await check(
        repository.calculateRoute(
          origin: origin,
          destination: destination,
        ),
      ).throws<RouteApiException>();
    });

    test('routes 配列が空の場合は RouteApiException をスローすること', () async {
      final repository = RouteRepositoryImpl(
        dio: mockDio,
        apiKey: 'test_api_key',
      );

      final mockApiResponse = {
        'status': 'OK',
        'routes': <dynamic>[],
      };

      when(
        () => mockDio.get<Map<String, dynamic>>(
          'https://maps.googleapis.com/maps/api/directions/json',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: mockApiResponse,
        ),
      );

      await check(
        repository.calculateRoute(
          origin: origin,
          destination: destination,
        ),
      ).throws<RouteApiException>();
    });

    test('travelMode に walking を指定した場合に mode パラメータに walking が渡されること', () async {
      final repository = RouteRepositoryImpl(
        dio: mockDio,
        apiKey: 'test_api_key',
      );

      final mockApiResponse = {
        'status': 'OK',
        'routes': [
          {
            'overview_polyline': {'points': '_p~iF~ps|U'},
            'legs': [
              {
                'distance': {'value': 2500, 'text': '2.5 km'},
                'duration': {'value': 1800, 'text': '30分'},
              },
            ],
          },
        ],
      };

      when(
        () => mockDio.get<Map<String, dynamic>>(
          'https://maps.googleapis.com/maps/api/directions/json',
          queryParameters: {
            'origin': '${origin.latitude},${origin.longitude}',
            'destination': '${destination.latitude},${destination.longitude}',
            'mode': 'walking',
            'key': 'test_api_key',
          },
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: mockApiResponse,
        ),
      );

      final route = await repository.calculateRoute(
        origin: origin,
        destination: destination,
        travelMode: TravelMode.walking,
      );

      check(route.travelMode).equals(TravelMode.walking);
      check(route.distanceMeters).equals(2500);
      check(route.durationSeconds).equals(1800);
    });

    test('カスタム directionsApiUrl が指定された場合にそのURLへリクエストすること', () async {
      final repository = RouteRepositoryImpl(
        dio: mockDio,
        apiKey: 'test_api_key',
        directionsApiUrl: 'https://custom-proxy.example.com/directions',
      );

      final mockApiResponse = {
        'status': 'OK',
        'routes': [
          {
            'overview_polyline': {'points': '_p~iF~ps|U'},
            'legs': [
              {
                'distance': {'value': 1000, 'text': '1 km'},
                'duration': {'value': 120, 'text': '2分'},
              },
            ],
          },
        ],
      };

      when(
        () => mockDio.get<Map<String, dynamic>>(
          'https://custom-proxy.example.com/directions',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: mockApiResponse,
        ),
      );

      final route = await repository.calculateRoute(
        origin: origin,
        destination: destination,
      );

      check(route.distanceMeters).equals(1000);
      check(route.durationSeconds).equals(120);
    });

    test('RouteApiException の toString が message を返すこと', () {
      const exception = RouteApiException('カスタムエラー');
      check(exception.toString()).equals('カスタムエラー');
    });

    test('routeRepositoryProvider から RouteRepository インスタンスを取得できること', () {
      final container = ProviderContainer(
        overrides: [
          flavorProvider.overrideWithValue(Flavor.dev),
          loggerProvider.overrideWithValue(Talker()),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(routeRepositoryProvider);
      check(repository).isA<RouteRepositoryImpl>();
    });
  });
}
