import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/data/geocoding_repository.dart';
import 'package:flutter_sample/src/features/map/domain/location_candidate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockGeocoding extends Mock implements Geocoding {}

void main() {
  late MockGeocoding mockGeocoding;
  late GeocodingRepository repository;

  setUp(() {
    mockGeocoding = MockGeocoding();
    repository = GeocodingRepository(geocoding: mockGeocoding);
  });

  group('GeocodingRepository Unit Tests', () {
    test('candidatesHandler が指定された場合、候補リストを返却すること', () async {
      final sampleCandidates = [
        const LocationCandidate(
          latitude: 35.681236,
          longitude: 139.767125,
          name: '東京駅',
          address: '東京都千代田区丸の内一丁目',
        ),
      ];

      final testRepo = GeocodingRepository(
        candidatesHandler: (address, {locale}) async => sampleCandidates,
      );

      final result = await testRepo.locationCandidatesFromAddress('東京駅');
      check(result).length.equals(1);
      check(result.first.name).equals('東京駅');
    });

    test(
      'locationCandidatesFromAddress: 住所および逆ジオコーディング情報を正常に取得できること',
      () async {
        final sampleLocations = [
          Location(
            latitude: 35.681236,
            longitude: 139.767125,
            timestamp: DateTime(2026, 8, 11),
          ),
        ];

        final samplePlacemarks = [
          const Placemark(
            name: '東京駅',
            street: '丸の内1',
            administrativeArea: '東京都',
            locality: '千代田区',
            subLocality: '丸の内',
          ),
        ];

        when(
          () => mockGeocoding.locationFromAddress('東京駅'),
        ).thenAnswer((_) async => sampleLocations);

        when(
          () => mockGeocoding.placemarkFromCoordinates(35.681236, 139.767125),
        ).thenAnswer((_) async => samplePlacemarks);

        final result = await repository.locationCandidatesFromAddress('東京駅');
        check(result).length.equals(1);
        check(result.first.latitude).equals(35.681236);
        check(result.first.longitude).equals(139.767125);
        check(result.first.name).equals('東京駅 丸の内1');
        check(result.first.address).equals('東京都千代田区丸の内');
      },
    );

    test('逆ジオコーディング失敗時にフォールバック表示名が設定されること', () async {
      final sampleLocations = [
        Location(
          latitude: 35.681236,
          longitude: 139.767125,
          timestamp: DateTime(2026, 8, 11),
        ),
      ];

      when(
        () => mockGeocoding.locationFromAddress('東京駅'),
      ).thenAnswer((_) async => sampleLocations);

      when(
        () => mockGeocoding.placemarkFromCoordinates(35.681236, 139.767125),
      ).thenThrow(Exception('Placemark error'));

      final result = await repository.locationCandidatesFromAddress('東京駅');
      check(result).length.equals(1);
      check(result.first.name).equals('東京駅');
    });

    test('thoroughfare が指定されている場合に address 名に設定されること', () async {
      final sampleLocations = [
        Location(
          latitude: 35.681236,
          longitude: 139.767125,
          timestamp: DateTime(2026, 8, 11),
        ),
      ];

      final samplePlacemarks = [
        const Placemark(
          name: '東京駅',
          street: '丸の内1',
          administrativeArea: '東京都',
          locality: '千代田区',
          subLocality: '丸の内',
          thoroughfare: '大手町1丁目',
        ),
      ];

      when(
        () => mockGeocoding.locationFromAddress('東京駅'),
      ).thenAnswer((_) async => sampleLocations);

      when(
        () => mockGeocoding.placemarkFromCoordinates(35.681236, 139.767125),
      ).thenAnswer((_) async => samplePlacemarks);

      final result = await repository.locationCandidatesFromAddress('東京駅');
      check(result).length.equals(1);
      check(result.first.address).equals('東京都千代田区丸の内大手町1丁目');
    });

    test('geocodingRepositoryProvider から正常にインスタンスが取得できること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(geocodingRepositoryProvider);
      check(repo).isA<GeocodingRepository>();
    });
  });
}
