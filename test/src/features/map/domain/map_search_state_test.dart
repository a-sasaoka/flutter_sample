import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/domain/location_candidate.dart';
import 'package:flutter_sample/src/features/map/domain/map_search_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapSearchState Unit Tests', () {
    test('initial 状態を正常にインスタンス化できること', () {
      const state = MapSearchState.initial();
      check(state).isA<MapSearchStateInitial>();
    });

    test('loading 状態を正常にインスタンス化できること', () {
      const state = MapSearchState.loading();
      check(state).isA<MapSearchStateLoading>();
    });

    test('success 状態を正常にインスタンス化できること', () {
      const candidate = LocationCandidate(
        latitude: 35.681236,
        longitude: 139.767125,
        name: '東京駅',
      );
      const state = MapSearchState.success(
        locations: [candidate],
        query: '東京駅',
      );
      check(state).isA<MapSearchStateSuccess>();
      state.whenOrNull(
        success: (locations, query) {
          check(locations.length).equals(1);
          check(query).equals('東京駅');
        },
      );
    });

    test('empty 状態を正常にインスタンス化できること', () {
      const state = MapSearchState.empty(query: '不明な場所');
      check(state).isA<MapSearchStateEmpty>();
      state.whenOrNull(
        empty: (query) {
          check(query).equals('不明な場所');
        },
      );
    });

    test('error 状態を正常にインスタンス化できること', () {
      const state = MapSearchState.error('Network Error');
      check(state).isA<MapSearchStateError>();
      state.whenOrNull(
        error: (message) {
          check(message).equals('Network Error');
        },
      );
    });
  });
}
