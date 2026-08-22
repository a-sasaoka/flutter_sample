import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/domain/location_candidate.dart';
import 'package:flutter_sample/src/features/map/domain/map_spot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationCandidate Unit Tests', () {
    test('LocationCandidate が正しくインスタンス化できること', () {
      const candidate = LocationCandidate(
        latitude: 35.681236,
        longitude: 139.767125,
        name: '東京駅',
        address: '東京都千代田区丸の内一丁目',
      );

      check(candidate.latitude).equals(35.681236);
      check(candidate.longitude).equals(139.767125);
      check(candidate.name).equals('東京駅');
      check(candidate.address).equals('東京都千代田区丸の内一丁目');
    });

    group('toMapSpot Tests', () {
      test('placeId がある場合、その placeId が id として使用されること', () {
        const candidate = LocationCandidate(
          latitude: 35.6585805,
          longitude: 139.7454329,
          name: '東京タワー',
          address: '東京都港区芝公園4-2-8',
          placeId: 'ChIJ...tokyo_tower',
          primaryType: 'tourist_attraction',
          rating: 4.6,
        );

        final spot = candidate.toMapSpot();

        check(spot.id).equals('ChIJ...tokyo_tower');
        check(spot.name).equals('東京タワー');
        check(spot.address).equals('東京都港区芝公園4-2-8');
        check(spot.latitude).equals(35.6585805);
        check(spot.longitude).equals(139.7454329);
        check(spot.rating).equals(4.6);
        check(spot.category).equals(SpotCategory.sightseeing);
      });

      test('placeId が null の場合、座標ベースの id が生成されること', () {
        const candidate = LocationCandidate(
          latitude: 35.681236,
          longitude: 139.767125,
          name: '東京駅',
        );

        final spot = candidate.toMapSpot();

        check(spot.id).equals('search_35.681236_139.767125');
        check(spot.category).equals(SpotCategory.other);
      });

      test('各種 primaryType が適切な SpotCategory にマッピングされること', () {
        SpotCategory getCategory(String? type) {
          return LocationCandidate(
            latitude: 35,
            longitude: 139,
            name: 'Test',
            primaryType: type,
          ).toMapSpot().category;
        }

        // cafe
        check(getCategory('cafe')).equals(SpotCategory.cafe);
        check(getCategory('coffee_shop')).equals(SpotCategory.cafe);

        // park
        check(getCategory('park')).equals(SpotCategory.park);
        check(getCategory('national_park')).equals(SpotCategory.park);

        // restaurant
        check(getCategory('restaurant')).equals(SpotCategory.restaurant);
        check(getCategory('food')).equals(SpotCategory.restaurant);
        check(getCategory('bar')).equals(SpotCategory.restaurant);

        // sightseeing
        check(
          getCategory('tourist_attraction'),
        ).equals(SpotCategory.sightseeing);
        check(getCategory('museum')).equals(SpotCategory.sightseeing);
        check(
          getCategory('historical_landmark'),
        ).equals(SpotCategory.sightseeing);
        check(
          getCategory('point_of_interest'),
        ).equals(SpotCategory.sightseeing);

        // shopping
        check(getCategory('shopping_mall')).equals(SpotCategory.shopping);
        check(getCategory('store')).equals(SpotCategory.shopping);
        check(getCategory('supermarket')).equals(SpotCategory.shopping);
        check(getCategory('department_store')).equals(SpotCategory.shopping);

        // other (unknown / null)
        check(getCategory('unknown_custom_type')).equals(SpotCategory.other);
        check(getCategory(null)).equals(SpotCategory.other);
      });
    });
  });
}
