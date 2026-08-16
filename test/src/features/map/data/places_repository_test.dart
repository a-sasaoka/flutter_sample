import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/map/data/places_repository.dart';
import 'package:flutter_sample/src/features/map/domain/location_candidate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('PlacesRepository Tests (Google Places API)', () {
    late MockDio mockDio;
    const testUrl = 'https://example.com/placesSearchProxy';

    setUp(() {
      mockDio = MockDio();
    });

    test('Google Places API 成功時に正常な LocationCandidate リストを生成して返すこと', () async {
      final repository = PlacesRepositoryImpl(
        dio: mockDio,
        placesApiUrl: testUrl,
      );

      final mockApiResponse = {
        'places': [
          {
            'id': 'place_123',
            'displayName': {'text': '東京駅'},
            'formattedAddress': '東京都千代田区丸の内１丁目',
            'location': {'latitude': 35.681236, 'longitude': 139.767125},
            'primaryType': 'train_station',
            'rating': 4.3,
          },
          {
            'id': 'place_456',
            'displayName': {'text': '東京スカイツリー'},
            'formattedAddress': '東京都墨田区押上１丁目１−２',
            'location': {'latitude': 35.710063, 'longitude': 139.8107},
            'primaryType': 'tourist_attraction',
            'rating': 4.6,
          },
        ],
      };

      when(
        () => mockDio.post<Map<String, dynamic>>(
          testUrl,
          data: {
            'textQuery': '東京',
            'languageCode': 'ja',
            'maxResultCount': 10,
          },
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: mockApiResponse,
        ),
      );

      final results = await repository.searchPlaces('東京');

      check(results.length).equals(2);
      check(results[0].name).equals('東京駅');
      check(results[0].address).equals('東京都千代田区丸の内１丁目');
      check(results[0].latitude).equals(35.681236);
      check(results[0].longitude).equals(139.767125);
      check(results[0].placeId).equals('place_123');
      check(results[0].primaryType).equals('train_station');
      check(results[0].rating).equals(4.3);

      check(results[1].name).equals('東京スカイツリー');
      check(results[1].placeId).equals('place_456');
    });

    test('空文字または空白のみのクエリの場合は API を呼ばずに空リストを返すこと', () async {
      final repository = PlacesRepositoryImpl(
        dio: mockDio,
        placesApiUrl: testUrl,
      );

      final results1 = await repository.searchPlaces('');
      final results2 = await repository.searchPlaces('   ');

      check(results1).isEmpty();
      check(results2).isEmpty();
      verifyNever(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      );
    });

    test('レスポンスデータが null の場合は PlacesApiException をスローすること', () async {
      final repository = PlacesRepositoryImpl(
        dio: mockDio,
        placesApiUrl: testUrl,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          testUrl,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
        ),
      );

      await check(
        repository.searchPlaces('東京'),
      ).throws<PlacesApiException>();
    });

    test('places リストが空の場合は空のリストを返すこと', () async {
      final repository = PlacesRepositoryImpl(
        dio: mockDio,
        placesApiUrl: testUrl,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          testUrl,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: {'places': <dynamic>[]},
        ),
      );

      final results = await repository.searchPlaces('存在しない地名');
      check(results).isEmpty();
    });

    test('不正なデータ（Map でない要素や座標欠損）は安全にスキップすること', () async {
      final repository = PlacesRepositoryImpl(
        dio: mockDio,
        placesApiUrl: testUrl,
      );

      final mockApiResponse = {
        'places': [
          '不正な文字列要素',
          {
            'id': 'missing_coords',
            'displayName': {'text': '座標なしスポット'},
          },
          {
            'id': 'valid_spot',
            'displayName': {'text': '有効スポット'},
            'location': {'latitude': 35.0, 'longitude': 139.0},
          },
        ],
      };

      when(
        () => mockDio.post<Map<String, dynamic>>(
          testUrl,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          data: mockApiResponse,
        ),
      );

      final results = await repository.searchPlaces('テスト');
      check(results.length).equals(1);
      check(results.first.name).equals('有効スポット');
    });

    test('401 未認証エラー時は適切な PlacesApiException をスローすること', () async {
      final repository = PlacesRepositoryImpl(
        dio: mockDio,
        placesApiUrl: testUrl,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          testUrl,
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 401,
            data: {'error': 'Unauthorized: ログインが必要です。'},
          ),
        ),
      );

      await check(
        repository.searchPlaces('東京'),
      ).throws<PlacesApiException>();
    });

    test('429 レート制限エラー時は適切な PlacesApiException をスローすること', () async {
      final repository = PlacesRepositoryImpl(
        dio: mockDio,
        placesApiUrl: testUrl,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          testUrl,
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 429,
            data: {'error': 'Too Many Requests: リクエストが多すぎます。'},
          ),
        ),
      );

      await check(
        repository.searchPlaces('東京'),
      ).throws<PlacesApiException>();
    });

    test('その他の DioException 時も PlacesApiException に変換してスローすること', () async {
      final repository = PlacesRepositoryImpl(
        dio: mockDio,
        placesApiUrl: testUrl,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          testUrl,
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          message: 'Connection timed out',
        ),
      );

      await check(
        repository.searchPlaces('東京'),
      ).throws<PlacesApiException>();
    });

    test('一般の例外も PlacesApiException にラップしてスローすること', () async {
      final repository = PlacesRepositoryImpl(
        dio: mockDio,
        placesApiUrl: testUrl,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          testUrl,
          data: any(named: 'data'),
        ),
      ).thenThrow(Exception('Unexpected error'));

      await check(
        repository.searchPlaces('東京'),
      ).throws<PlacesApiException>();
    });

    test('PlacesApiException の toString が message を返すこと', () {
      const exception = PlacesApiException('カスタムエラー', statusCode: 400);
      check(exception.toString()).equals('カスタムエラー');
      check(exception.statusCode).equals(400);
    });

    group('MockPlacesRepositoryImpl Tests', () {
      test('デフォルトのダミー候補を正常に生成して返すこと', () async {
        const mockRepo = MockPlacesRepositoryImpl();
        final results = await mockRepo.searchPlaces('新宿');

        check(results.length).equals(2);
        check(results.first.name).contains('新宿');
        check(results.first.latitude).equals(35.6895);
      });

      test('カスタムモック候補地を指定した場合にそれを返すこと', () async {
        final customCandidates = [
          const LocationCandidate(
            latitude: 34,
            longitude: 135,
            name: '大阪城',
          ),
        ];
        final mockRepo = MockPlacesRepositoryImpl(
          mockCandidates: customCandidates,
        );
        final results = await mockRepo.searchPlaces('大阪');

        check(results.length).equals(1);
        check(results.first.name).equals('大阪城');
      });

      test('遅延設定がある場合に待機すること', () async {
        const mockRepo = MockPlacesRepositoryImpl(
          delay: Duration(milliseconds: 10),
        );
        final stopwatch = Stopwatch()..start();
        final results = await mockRepo.searchPlaces('テスト');
        stopwatch.stop();

        check(results).isNotEmpty();
        check(stopwatch.elapsedMilliseconds).isGreaterThan(5);
      });

      test('shouldThrow が true の場合に例外をスローすること', () async {
        const mockRepo = MockPlacesRepositoryImpl(shouldThrow: true);
        await check(
          mockRepo.searchPlaces('テスト'),
        ).throws<PlacesApiException>();
      });
    });

    test('placesRepositoryProvider が PlacesRepositoryImpl を返すこと', () {
      final container = ProviderContainer(
        overrides: [
          flavorProvider.overrideWithValue(Flavor.local),
          loggerProvider.overrideWithValue(Talker()),
        ],
      );
      addTearDown(container.dispose);
      check(
        container.read(placesRepositoryProvider),
      ).isA<PlacesRepositoryImpl>();
    });
  });
}
