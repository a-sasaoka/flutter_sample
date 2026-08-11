import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/application/map_search_notifier.dart';
import 'package:flutter_sample/src/features/map/data/geocoding_repository.dart';
import 'package:flutter_sample/src/features/map/domain/map_search_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockGeocodingRepository extends Mock implements GeocodingRepository {}

void main() {
  late MockGeocodingRepository mockRepository;

  setUp(() {
    mockRepository = MockGeocodingRepository();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        geocodingRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('MapSearchNotifier Unit Tests', () {
    test('初期状態は MapSearchState.initial であること', () {
      final container = createContainer();
      final state = container.read(mapSearchProvider);
      check(state).isA<MapSearchStateInitial>();
    });

    test('空文字または空白クエリの場合、initial 状態がセットされること', () async {
      final container = createContainer()..listen(mapSearchProvider, (_, _) {});

      final notifier = container.read(mapSearchProvider.notifier);
      await notifier.searchLocation('   ');

      final state = container.read(mapSearchProvider);
      check(state).isA<MapSearchStateInitial>();
    });

    test('検索成功時、MapSearchState.success 状態に遷移すること', () async {
      final sampleLocations = [
        Location(
          latitude: 35.681236,
          longitude: 139.767125,
          timestamp: DateTime(2026, 8, 11),
        ),
      ];

      when(
        () => mockRepository.locationFromAddressQuery('東京駅'),
      ).thenAnswer((_) async => sampleLocations);

      final container = createContainer()..listen(mapSearchProvider, (_, _) {});

      final notifier = container.read(mapSearchProvider.notifier);
      await notifier.searchLocation('東京駅');

      final state = container.read(mapSearchProvider);
      check(state).isA<MapSearchStateSuccess>();
      final successState = state as MapSearchStateSuccess;
      check(successState.locations).length.equals(1);
      check(successState.query).equals('東京駅');
    });

    test('該当件数なしの場合、MapSearchState.empty 状態に遷移すること', () async {
      when(
        () => mockRepository.locationFromAddressQuery('存在しない場所XYZ'),
      ).thenAnswer((_) async => <Location>[]);

      final container = createContainer()..listen(mapSearchProvider, (_, _) {});

      final notifier = container.read(mapSearchProvider.notifier);
      await notifier.searchLocation('存在しない場所XYZ');

      final state = container.read(mapSearchProvider);
      check(state).isA<MapSearchStateEmpty>();
      final emptyState = state as MapSearchStateEmpty;
      check(emptyState.query).equals('存在しない場所XYZ');
    });

    test('エラー発生時、MapSearchState.error 状態に遷移すること', () async {
      when(
        () => mockRepository.locationFromAddressQuery('エラークエリ'),
      ).thenThrow(Exception('Geocoding Failed'));

      final container = createContainer()..listen(mapSearchProvider, (_, _) {});

      final notifier = container.read(mapSearchProvider.notifier);
      await notifier.searchLocation('エラークエリ');

      final state = container.read(mapSearchProvider);
      check(state).isA<MapSearchStateError>();
      final errorState = state as MapSearchStateError;
      check(errorState.message).contains('Geocoding Failed');
    });

    test('clearSearch 呼び出し時、initial 状態にリセットされること', () async {
      final sampleLocations = [
        Location(
          latitude: 35.681236,
          longitude: 139.767125,
          timestamp: DateTime(2026, 8, 11),
        ),
      ];

      when(
        () => mockRepository.locationFromAddressQuery('東京駅'),
      ).thenAnswer((_) async => sampleLocations);

      final container = createContainer()..listen(mapSearchProvider, (_, _) {});

      final notifier = container.read(mapSearchProvider.notifier);
      await notifier.searchLocation('東京駅');

      notifier.clearSearch();

      final state = container.read(mapSearchProvider);
      check(state).isA<MapSearchStateInitial>();
    });
  });
}
