import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/application/map_search_notifier.dart';
import 'package:flutter_sample/src/features/map/data/geocoding_repository.dart';
import 'package:flutter_sample/src/features/map/domain/location_candidate.dart';
import 'package:flutter_sample/src/features/map/domain/map_search_state.dart';
import 'package:flutter_test/flutter_test.dart';
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
      final sampleCandidates = [
        const LocationCandidate(
          latitude: 35.681236,
          longitude: 139.767125,
          name: '東京駅',
        ),
      ];

      when(
        () => mockRepository.locationCandidatesFromAddress('東京駅'),
      ).thenAnswer((_) async => sampleCandidates);

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
        () => mockRepository.locationCandidatesFromAddress('存在しない場所XYZ'),
      ).thenAnswer((_) async => <LocationCandidate>[]);

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
        () => mockRepository.locationCandidatesFromAddress('エラークエリ'),
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
      final sampleCandidates = [
        const LocationCandidate(
          latitude: 35.681236,
          longitude: 139.767125,
          name: '東京駅',
        ),
      ];

      when(
        () => mockRepository.locationCandidatesFromAddress('東京駅'),
      ).thenAnswer((_) async => sampleCandidates);

      final container = createContainer()..listen(mapSearchProvider, (_, _) {});

      final notifier = container.read(mapSearchProvider.notifier);
      await notifier.searchLocation('東京駅');

      notifier.clearSearch();

      final state = container.read(mapSearchProvider);
      check(state).isA<MapSearchStateInitial>();
    });

    test('後から開始された検索が先に完了した場合、古い非同期レスポンスが無視されること', () async {
      final sampleCandidates1 = [
        const LocationCandidate(
          latitude: 35.681236,
          longitude: 139.767125,
          name: '東京駅',
        ),
      ];
      final sampleCandidates2 = [
        const LocationCandidate(
          latitude: 35.689487,
          longitude: 139.691706,
          name: '新宿駅',
        ),
      ];

      final completer1 = Completer<List<LocationCandidate>>();
      final completer2 = Completer<List<LocationCandidate>>();

      when(
        () => mockRepository.locationCandidatesFromAddress('東京駅'),
      ).thenAnswer((_) => completer1.future);

      when(
        () => mockRepository.locationCandidatesFromAddress('新宿駅'),
      ).thenAnswer((_) => completer2.future);

      final container = createContainer()..listen(mapSearchProvider, (_, _) {});

      final notifier = container.read(mapSearchProvider.notifier);

      unawaited(notifier.searchLocation('東京駅'));
      unawaited(notifier.searchLocation('新宿駅'));

      completer2.complete(sampleCandidates2);
      await pumpEventQueue();

      final stateAfter2 = container.read(mapSearchProvider);
      check(stateAfter2).isA<MapSearchStateSuccess>();
      final successState2 = stateAfter2 as MapSearchStateSuccess;
      check(successState2.query).equals('新宿駅');

      completer1.complete(sampleCandidates1);
      await pumpEventQueue();

      final finalState = container.read(mapSearchProvider);
      check(finalState).isA<MapSearchStateSuccess>();
      final finalSuccessState = finalState as MapSearchStateSuccess;
      check(finalSuccessState.query).equals('新宿駅');
    });

    test('clearSearch 呼び出し後に完了した古い非同期レスポンスが無視されること', () async {
      final sampleCandidates = [
        const LocationCandidate(
          latitude: 35.681236,
          longitude: 139.767125,
          name: '東京駅',
        ),
      ];

      final completer = Completer<List<LocationCandidate>>();

      when(
        () => mockRepository.locationCandidatesFromAddress('東京駅'),
      ).thenAnswer((_) => completer.future);

      final container = createContainer()..listen(mapSearchProvider, (_, _) {});

      final notifier = container.read(mapSearchProvider.notifier);

      unawaited(notifier.searchLocation('東京駅'));

      notifier.clearSearch();

      completer.complete(sampleCandidates);
      await pumpEventQueue();

      final state = container.read(mapSearchProvider);
      check(state).isA<MapSearchStateInitial>();
    });
  });
}
