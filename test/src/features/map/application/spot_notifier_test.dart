import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/application/spot_notifier.dart';
import 'package:flutter_sample/src/features/map/data/spot_repository.dart';
import 'package:flutter_sample/src/features/map/domain/map_spot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockSpotRepository extends Mock implements SpotRepository {}

void main() {
  late MockSpotRepository mockRepository;

  setUp(() {
    mockRepository = MockSpotRepository();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        spotRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SpotNotifier Unit Tests', () {
    test('build 呼び出し時に SpotRepository からスポット一覧を取得して AsyncData を返すこと', () async {
      const sampleSpots = [
        MapSpot(
          id: 'spot_1',
          name: '東京タワー',
          category: SpotCategory.sightseeing,
          latitude: 35.6585805,
          longitude: 139.7454329,
        ),
      ];

      when(
        () => mockRepository.getSpots(),
      ).thenAnswer((_) async => sampleSpots);

      final container = createContainer()..listen(spotProvider, (_, _) {});

      final state = await container.read(spotProvider.future);
      check(state).length.equals(1);
      check(state.first.name).equals('東京タワー');
    });

    test('fetchSpots 実行時に AsyncValue が更新されること', () async {
      const initialSpots = [
        MapSpot(
          id: 'spot_1',
          name: '東京タワー',
          category: SpotCategory.sightseeing,
          latitude: 35.6585805,
          longitude: 139.7454329,
        ),
      ];

      const refreshedSpots = [
        MapSpot(
          id: 'spot_2',
          name: '代々木公園',
          category: SpotCategory.park,
          latitude: 35.671736,
          longitude: 139.694945,
        ),
      ];

      when(
        () => mockRepository.getSpots(),
      ).thenAnswer((_) async => initialSpots);

      final container = createContainer()..listen(spotProvider, (_, _) {});
      final initialState = await container.read(spotProvider.future);
      check(initialState.first.name).equals('東京タワー');

      when(
        () => mockRepository.getSpots(),
      ).thenAnswer((_) async => refreshedSpots);

      final notifier = container.read(spotProvider.notifier);
      await notifier.fetchSpots();

      final state = container.read(spotProvider);
      check(state).isA<AsyncData<List<MapSpot>>>();
      check(state.value!).length.equals(1);
      check(state.value!.first.name).equals('代々木公園');

      verify(() => mockRepository.getSpots()).called(2);
    });
  });
}
