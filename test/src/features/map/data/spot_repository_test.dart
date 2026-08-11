import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/data/spot_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpotRepository Tests', () {
    test('getSpots はサンプルスポットのリストを返すこと', () async {
      final repository = SpotRepositoryImpl();
      final spots = await repository.getSpots();

      check(spots).isNotEmpty();
      check(spots.length).equals(SpotRepositoryImpl.sampleSpots.length);
      check(spots.first.name).equals('東京タワー');
    });

    test('getSpotById は存在する ID の場合該当スポットを返し、存在しない場合 null を返すこと', () async {
      final repository = SpotRepositoryImpl();
      final spot = await repository.getSpotById('spot_tokyo_tower');
      check(spot).isNotNull();
      check(spot!.name).equals('東京タワー');

      final unknown = await repository.getSpotById('unknown_id');
      check(unknown).isNull();
    });

    test('spotRepositoryProvider から SpotRepository インスタンスを取得できること', () {
      final container = spotRepositoryProvider.overrideWithValue(
        SpotRepositoryImpl(),
      );
      check(container).isNotNull();
    });
  });
}
