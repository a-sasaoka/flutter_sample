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
  group('RouteRepository Tests (Google Routes API)', () {
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
    });

    const origin = LatLng(35.681236, 139.767125);
    const destination = LatLng(35.6585805, 139.7454329);
    const expectedUrl =
        'https://routes.googleapis.com/directions/v2:computeRoutes';

    test('Google Routes API 成功時に正常な MapRoute を生成して返すこと', () async {
      final repository = RouteRepositoryImpl(
        dio: mockDio,
        apiKey: 'test_api_key',
      );

      final mockApiResponse = {
        'routes': [
          {
            'polyline': {
              'encodedPolyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
            },
            'distanceMeters': 4200,
            'duration': '480s',
          },
        ],
      };

      when(
        () => mockDio.post<Map<String, dynamic>>(
          expectedUrl,
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
            'travelMode': 'DRIVE',
          },
          options: any(named: 'options'),
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
      check(route.travelMode).equals(TravelMode.driving);
    });

    test(
      'polyline や duration が空の場合でもフォールバックして MapRoute を生成すること',
      () async {
        final repository = RouteRepositoryImpl(
          dio: mockDio,
          apiKey: 'test_api_key',
        );

        final mockApiResponse = {
          'routes': [
            <String, dynamic>{},
          ],
        };

        when(
          () => mockDio.post<Map<String, dynamic>>(
            expectedUrl,
            data: any(named: 'data'),
            options: any(named: 'options'),
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
        () => mockDio.post<Map<String, dynamic>>(
          expectedUrl,
          data: any(named: 'data'),
          options: any(named: 'options'),
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

    test('routes 配列が空の場合は RouteApiException をスローすること', () async {
      final repository = RouteRepositoryImpl(
        dio: mockDio,
        apiKey: 'test_api_key',
      );

      final mockApiResponse = {
        'routes': <dynamic>[],
      };

      when(
        () => mockDio.post<Map<String, dynamic>>(
          expectedUrl,
          data: any(named: 'data'),
          options: any(named: 'options'),
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

    test('DioException 発生時に API エラーメッセージを抽出してスローすること', () async {
      final repository = RouteRepositoryImpl(
        dio: mockDio,
        apiKey: 'test_api_key',
      );

      final dioException = DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          data: {
            'error': {
              'code': 400,
              'message': 'API key not valid. Please pass a valid API key.',
              'status': 'INVALID_ARGUMENT',
            },
          },
        ),
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          expectedUrl,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(dioException);

      await check(
        repository.calculateRoute(
          origin: origin,
          destination: destination,
        ),
      ).throws<RouteApiException>();
    });

    test('DioException 発生時にレスポンスがない場合 DioException.message をスローすること', () async {
      final repository = RouteRepositoryImpl(
        dio: mockDio,
        apiKey: 'test_api_key',
      );

      final dioException = DioException(
        requestOptions: RequestOptions(),
        message: 'ネットワーク接続エラー',
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          expectedUrl,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(dioException);

      await check(
        repository.calculateRoute(
          origin: origin,
          destination: destination,
        ),
      ).throws<RouteApiException>();
    });

    test('travelMode に walking を指定した場合に travelMode に WALK が渡されること', () async {
      final repository = RouteRepositoryImpl(
        dio: mockDio,
        apiKey: 'test_api_key',
      );

      final mockApiResponse = {
        'routes': [
          {
            'polyline': {'encodedPolyline': '_p~iF~ps|U'},
            'distanceMeters': 2500,
            'duration': '1800s',
          },
        ],
      };

      when(
        () => mockDio.post<Map<String, dynamic>>(
          expectedUrl,
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
            'travelMode': 'WALK',
          },
          options: any(named: 'options'),
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

    test('duration が数値または末尾sなし文字列の場合でも正しくパースされること', () async {
      final repository = RouteRepositoryImpl(
        dio: mockDio,
        apiKey: 'test_api_key',
      );

      final mockApiResponse = {
        'routes': [
          {
            'polyline': {'encodedPolyline': '_p~iF~ps|U'},
            'distanceMeters': 1000,
            'duration': 300,
          },
        ],
      };

      when(
        () => mockDio.post<Map<String, dynamic>>(
          expectedUrl,
          data: any(named: 'data'),
          options: any(named: 'options'),
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

      check(route.durationSeconds).equals(300);
    });

    test('カスタム directionsApiUrl が指定された場合にそのURLへ POST リクエストすること', () async {
      final repository = RouteRepositoryImpl(
        dio: mockDio,
        apiKey: 'test_api_key',
        directionsApiUrl: 'https://custom-proxy.example.com/computeRoutes',
      );

      final mockApiResponse = {
        'routes': [
          {
            'polyline': {'encodedPolyline': '_p~iF~ps|U'},
            'distanceMeters': 1000,
            'duration': '120s',
          },
        ],
      };

      when(
        () => mockDio.post<Map<String, dynamic>>(
          'https://custom-proxy.example.com/computeRoutes',
          data: any(named: 'data'),
          options: any(named: 'options'),
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
