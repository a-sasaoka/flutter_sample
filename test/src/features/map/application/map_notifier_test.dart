import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/map/application/map_notifier.dart';
import 'package:flutter_sample/src/features/map/data/location_repository.dart';
import 'package:flutter_sample/src/features/map/domain/location_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

class MockTalker extends Mock implements Talker {}

void main() {
  late MockLocationRepository mockRepository;
  late MockTalker mockTalker;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
  });

  setUp(() {
    mockRepository = MockLocationRepository();
    mockTalker = MockTalker();
    container = ProviderContainer(
      overrides: [
        locationRepositoryProvider.overrideWithValue(mockRepository),
        loggerProvider.overrideWithValue(mockTalker),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('MapNotifier Tests', () {
    test('初期状態は LocationStateInitial であること', () {
      final state = container.read(mapProvider);
      check(state).isA<LocationStateInitial>();
    });

    test('GPS無効時は serviceDisabled に状態遷移すること', () async {
      when(() => mockTalker.warning(any<dynamic>())).thenReturn(null);
      when(
        () => mockRepository.isLocationServiceEnabled(),
      ).thenAnswer((_) async => false);

      final notifier = container.read(mapProvider.notifier);
      await notifier.fetchCurrentLocation();

      final state = container.read(mapProvider);
      check(state).isA<LocationStateServiceDisabled>();
    });

    test('権限拒否時は permissionDenied に状態遷移すること', () async {
      when(() => mockTalker.warning(any<dynamic>())).thenReturn(null);
      when(
        () => mockRepository.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRepository.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      when(
        () => mockRepository.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);

      final notifier = container.read(mapProvider.notifier);
      await notifier.fetchCurrentLocation();

      final state = container.read(mapProvider);
      check(state).isA<LocationStatePermissionDenied>();
    });

    test('権限永久拒否時は permissionDeniedForever に状態遷移すること', () async {
      when(() => mockTalker.warning(any<dynamic>())).thenReturn(null);
      when(
        () => mockRepository.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRepository.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.deniedForever);

      final notifier = container.read(mapProvider.notifier);
      await notifier.fetchCurrentLocation();

      final state = container.read(mapProvider);
      check(state).isA<LocationStatePermissionDeniedForever>();
    });

    test('正常に位置情報が取得できた場合は success に状態遷移すること', () async {
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

      when(() => mockTalker.info(any<dynamic>())).thenReturn(null);
      when(
        () => mockRepository.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => mockRepository.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);
      when(
        () => mockRepository.getCurrentPosition(),
      ).thenAnswer((_) async => mockPosition);

      final notifier = container.read(mapProvider.notifier);
      await notifier.fetchCurrentLocation();

      final state = container.read(mapProvider);
      check(state).isA<LocationStateSuccess>();
      final successState = state as LocationStateSuccess;
      check(successState.position.latitude).equals(35.681236);
    });

    test('例外発生時は error 状態に遷移すること', () async {
      when(
        () => mockTalker.handle(any<Object>(), any<StackTrace>()),
      ).thenReturn(null);
      when(
        () => mockRepository.isLocationServiceEnabled(),
      ).thenThrow(Exception('GPS Error'));

      final notifier = container.read(mapProvider.notifier);
      await notifier.fetchCurrentLocation();

      final state = container.read(mapProvider);
      check(state).isA<LocationStateError>();
    });

    test('openAppSettings がリポジトリの openAppSettings を呼び出すこと', () async {
      when(
        () => mockRepository.openAppSettings(),
      ).thenAnswer((_) async => true);

      final notifier = container.read(mapProvider.notifier);
      await notifier.openAppSettings();

      verify(() => mockRepository.openAppSettings()).called(1);
    });

    test('openLocationSettings がリポジトリの openLocationSettings を呼び出すこと', () async {
      when(
        () => mockRepository.openLocationSettings(),
      ).thenAnswer((_) async => true);

      final notifier = container.read(mapProvider.notifier);
      await notifier.openLocationSettings();

      verify(() => mockRepository.openLocationSettings()).called(1);
    });
  });
}
