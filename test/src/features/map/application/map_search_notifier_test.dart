import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/map/application/map_search_notifier.dart';
import 'package:flutter_sample/src/features/map/data/geocoding_repository.dart';
import 'package:flutter_sample/src/features/map/data/places_repository.dart';
import 'package:flutter_sample/src/features/map/domain/location_candidate.dart';
import 'package:flutter_sample/src/features/map/domain/map_search_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockPlacesRepository extends Mock implements PlacesRepository {}

class MockGeocodingRepository extends Mock implements GeocodingRepository {}

class HandleCall {
  const HandleCall({
    required this.exception,
    this.stackTrace,
    this.msg,
  });

  final Object exception;
  final StackTrace? stackTrace;
  final String? msg;
}

class SpyTalker extends Talker {
  SpyTalker() : super(settings: TalkerSettings(enabled: false));

  final List<HandleCall> handleCalls = [];
  final List<String> infoLogs = [];

  @override
  void handle(
    Object exception, [
    StackTrace? stackTrace,
    dynamic msg,
  ]) {
    handleCalls.add(
      HandleCall(
        exception: exception,
        stackTrace: stackTrace,
        msg: msg?.toString(),
      ),
    );
    super.handle(exception, stackTrace, msg);
  }

  @override
  void info(dynamic msg, [Object? exception, StackTrace? stackTrace]) {
    infoLogs.add(msg.toString());
    super.info(msg, exception, stackTrace);
  }
}

void main() {
  late MockPlacesRepository mockPlacesRepository;
  late MockGeocodingRepository mockGeocodingRepository;
  late SpyTalker spyTalker;

  setUp(() {
    mockPlacesRepository = MockPlacesRepository();
    mockGeocodingRepository = MockGeocodingRepository();
    spyTalker = SpyTalker();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        placesRepositoryProvider.overrideWithValue(mockPlacesRepository),
        geocodingRepositoryProvider.overrideWithValue(mockGeocodingRepository),
        loggerProvider.overrideWithValue(spyTalker),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('MapSearchNotifier Unit Tests (Places API & Geocoding Fallback)', () {
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

    test('Google Places API 検索成功時、MapSearchState.success 状態に遷移すること', () async {
      final sampleCandidates = [
        const LocationCandidate(
          latitude: 35.681236,
          longitude: 139.767125,
          name: '東京駅',
          placeId: 'places_123',
        ),
      ];

      when(
        () => mockPlacesRepository.searchPlaces('東京駅'),
      ).thenAnswer((_) async => sampleCandidates);

      final container = createContainer()..listen(mapSearchProvider, (_, _) {});

      final notifier = container.read(mapSearchProvider.notifier);
      await notifier.searchLocation('東京駅');

      final state = container.read(mapSearchProvider);
      check(state).isA<MapSearchStateSuccess>();
      final successState = state as MapSearchStateSuccess;
      check(successState.locations).length.equals(1);
      check(successState.locations.first.placeId).equals('places_123');
      check(successState.query).equals('東京駅');
      verifyNever(
        () => mockGeocodingRepository.locationCandidatesFromAddress(any()),
      );
    });

    test(
      'Places API がエラーの時、GeocodingRepository に自動フォールバックして成功すること',
      () async {
        const placesError = PlacesApiException(
          'Network Error',
          statusCode: 500,
        );
        when(
          () => mockPlacesRepository.searchPlaces('東京タワー'),
        ).thenThrow(placesError);

        final fallbackCandidates = [
          const LocationCandidate(
            latitude: 35.6585805,
            longitude: 139.7454329,
            name: '東京タワー',
          ),
        ];
        when(
          () => mockGeocodingRepository.locationCandidatesFromAddress('東京タワー'),
        ).thenAnswer((_) async => fallbackCandidates);

        final container = createContainer()
          ..listen(mapSearchProvider, (_, _) {});

        final notifier = container.read(mapSearchProvider.notifier);
        await notifier.searchLocation('東京タワー');

        final state = container.read(mapSearchProvider);
        check(state).isA<MapSearchStateSuccess>();
        final successState = state as MapSearchStateSuccess;
        check(successState.locations).length.equals(1);
        check(successState.locations.first.name).equals('東京タワー');

        // Places API のエラーが Talker に記録されていること
        check(spyTalker.handleCalls).length.equals(1);
        check(spyTalker.handleCalls.first.exception).equals(placesError);
        check(spyTalker.handleCalls.first.stackTrace).isNotNull();
        check(
          spyTalker.handleCalls.first.msg,
        ).isNotNull().contains(
          'Places API 検索でエラーが発生したため、 Geocoding にフォールバックします',
        );
      },
    );

    test(
      'Places API が空の時、GeocodingRepository にフォールバックして成功すること',
      () async {
        when(
          () => mockPlacesRepository.searchPlaces('東京タワー'),
        ).thenAnswer((_) async => <LocationCandidate>[]);

        final fallbackCandidates = [
          const LocationCandidate(
            latitude: 35.6585805,
            longitude: 139.7454329,
            name: '東京タワー',
          ),
        ];
        when(
          () => mockGeocodingRepository.locationCandidatesFromAddress('東京タワー'),
        ).thenAnswer((_) async => fallbackCandidates);

        final container = createContainer()
          ..listen(mapSearchProvider, (_, _) {});

        final notifier = container.read(mapSearchProvider.notifier);
        await notifier.searchLocation('東京タワー');

        final state = container.read(mapSearchProvider);
        check(state).isA<MapSearchStateSuccess>();
        final successState = state as MapSearchStateSuccess;
        check(successState.locations).length.equals(1);

        // Places API 0件時の info ログが出力されていること
        check(
          spyTalker.infoLogs,
        ).any(
          (log) =>
              log.contains('Places API の検索結果が 0 件だったため、 Geocoding にフォールバックします'),
        );
      },
    );

    test('Places と Geocoding の両方で該当件数なしの場合、empty 状態に遷移すること', () async {
      when(
        () => mockPlacesRepository.searchPlaces('存在しない場所XYZ'),
      ).thenAnswer((_) async => <LocationCandidate>[]);

      when(
        () =>
            mockGeocodingRepository.locationCandidatesFromAddress('存在しない場所XYZ'),
      ).thenAnswer((_) async => <LocationCandidate>[]);

      final container = createContainer()..listen(mapSearchProvider, (_, _) {});

      final notifier = container.read(mapSearchProvider.notifier);
      await notifier.searchLocation('存在しない場所XYZ');

      final state = container.read(mapSearchProvider);
      check(state).isA<MapSearchStateEmpty>();
      final emptyState = state as MapSearchStateEmpty;
      check(emptyState.query).equals('存在しない場所XYZ');
    });

    test('フォールバック先の Geocoding で例外発生時、error 状態に遷移すること', () async {
      when(
        () => mockPlacesRepository.searchPlaces('エラークエリ'),
      ).thenAnswer((_) async => <LocationCandidate>[]);

      final geocodingError = Exception('Geocoding Failed');
      when(
        () => mockGeocodingRepository.locationCandidatesFromAddress('エラークエリ'),
      ).thenThrow(geocodingError);

      final container = createContainer()..listen(mapSearchProvider, (_, _) {});

      final notifier = container.read(mapSearchProvider.notifier);
      await notifier.searchLocation('エラークエリ');

      final state = container.read(mapSearchProvider);
      check(state).isA<MapSearchStateError>();
      final errorState = state as MapSearchStateError;
      check(errorState.message).contains('Geocoding Failed');
      check(spyTalker.handleCalls).length.equals(1);
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
        () => mockPlacesRepository.searchPlaces('東京駅'),
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
        () => mockPlacesRepository.searchPlaces('東京駅'),
      ).thenAnswer((_) => completer1.future);

      when(
        () => mockPlacesRepository.searchPlaces('新宿駅'),
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
        () => mockPlacesRepository.searchPlaces('東京駅'),
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

    test('Notifier が dispose された場合、非同期完了後の状態更新が行われないこと', () async {
      final completer = Completer<List<LocationCandidate>>();

      when(
        () => mockPlacesRepository.searchPlaces('東京駅'),
      ).thenAnswer((_) => completer.future);

      final container = ProviderContainer(
        overrides: [
          placesRepositoryProvider.overrideWithValue(mockPlacesRepository),
          geocodingRepositoryProvider.overrideWithValue(
            mockGeocodingRepository,
          ),
          loggerProvider.overrideWithValue(spyTalker),
        ],
      )..listen(mapSearchProvider, (_, _) {});

      final notifier = container.read(mapSearchProvider.notifier);
      unawaited(notifier.searchLocation('東京駅'));

      container.dispose();

      completer.complete([
        const LocationCandidate(
          latitude: 35.681236,
          longitude: 139.767125,
          name: '東京駅',
        ),
      ]);

      await pumpEventQueue();
    });

    test(
      'Notifier が dispose された後に非同期例外が発生した場合でも、handle 呼び出しが安全にスキップされること',
      () async {
        final completer = Completer<List<LocationCandidate>>();

        when(
          () => mockPlacesRepository.searchPlaces('東京駅'),
        ).thenAnswer((_) => completer.future);

        final container = ProviderContainer(
          overrides: [
            placesRepositoryProvider.overrideWithValue(mockPlacesRepository),
            geocodingRepositoryProvider.overrideWithValue(
              mockGeocodingRepository,
            ),
            loggerProvider.overrideWithValue(spyTalker),
          ],
        )..listen(mapSearchProvider, (_, _) {});

        final notifier = container.read(mapSearchProvider.notifier);
        unawaited(notifier.searchLocation('東京駅'));

        container.dispose();

        final delayedError = Exception('遅延エラー');
        completer.completeError(delayedError);

        await pumpEventQueue();

        // dispose されたため非同期例外の handle 呼び出しは安全にスキップされること
        check(spyTalker.handleCalls).isEmpty();
      },
    );
  });
}
