import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/data/location_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockGeolocatorPlatform extends Mock implements GeolocatorPlatform {}

void main() {
  late MockGeolocatorPlatform mockGeolocator;
  late LocationRepository repository;

  setUp(() {
    mockGeolocator = MockGeolocatorPlatform();
    repository = LocationRepository(geolocator: mockGeolocator);
  });

  group('LocationRepository Tests', () {
    test('isLocationServiceEnabled は Geolocator の結果を返すこと', () async {
      when(
        () => mockGeolocator.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);

      final result = await repository.isLocationServiceEnabled();

      check(result).isTrue();
      verify(() => mockGeolocator.isLocationServiceEnabled()).called(1);
    });

    test('checkPermission は Geolocator のパーミッション状態を返すこと', () async {
      when(
        () => mockGeolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);

      final result = await repository.checkPermission();

      check(result).equals(LocationPermission.whileInUse);
      verify(() => mockGeolocator.checkPermission()).called(1);
    });

    test('requestPermission は要求結果のパーミッション状態を返すこと', () async {
      when(
        () => mockGeolocator.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.always);

      final result = await repository.requestPermission();

      check(result).equals(LocationPermission.always);
      verify(() => mockGeolocator.requestPermission()).called(1);
    });

    test('getCurrentPosition は取得した Position オブジェクトを返すこと', () async {
      final mockPosition = Position(
        longitude: 139.767125,
        latitude: 35.681236,
        timestamp: DateTime(2026, 8, 11),
        accuracy: 5,
        altitude: 10,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      when(
        () => mockGeolocator.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer((_) async => mockPosition);

      final position = await repository.getCurrentPosition();

      check(position.latitude).equals(35.681236);
      check(position.longitude).equals(139.767125);
    });

    test('openAppSettings は Geolocator の結果を返すこと', () async {
      when(
        () => mockGeolocator.openAppSettings(),
      ).thenAnswer((_) async => true);

      final result = await repository.openAppSettings();

      check(result).isTrue();
      verify(() => mockGeolocator.openAppSettings()).called(1);
    });

    test('openLocationSettings は Geolocator の結果を返すこと', () async {
      when(
        () => mockGeolocator.openLocationSettings(),
      ).thenAnswer((_) async => true);

      final result = await repository.openLocationSettings();

      check(result).isTrue();
      verify(() => mockGeolocator.openLocationSettings()).called(1);
    });

    test('locationRepositoryProvider は LocationRepository のインスタンスを生成すること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(locationRepositoryProvider);
      check(repo).isA<LocationRepository>();
    });
  });
}
