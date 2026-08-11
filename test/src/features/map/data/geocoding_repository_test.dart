import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/data/geocoding_repository.dart';
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
    test('locationFromAddressQuery: 住所から座標のリストを取得できること', () async {
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

      final result = await repository.locationFromAddressQuery('東京駅');
      check(result).length.equals(1);
      check(result.first.latitude).equals(35.681236);
      check(result.first.longitude).equals(139.767125);
    });

    test('geocodingRepositoryProvider から正常にインスタンスが取得できること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(geocodingRepositoryProvider);
      check(repo).isA<GeocodingRepository>();
    });
  });
}
