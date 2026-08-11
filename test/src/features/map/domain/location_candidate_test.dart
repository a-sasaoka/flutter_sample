import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/domain/location_candidate.dart';
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
  });
}
