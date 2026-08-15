import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/map/application/map_route_notifier.dart';
import 'package:flutter_sample/src/features/map/data/route_repository.dart';
import 'package:flutter_sample/src/features/map/domain/map_route.dart';
import 'package:flutter_sample/src/features/map/domain/map_route_state.dart';
import 'package:flutter_sample/src/features/map/domain/travel_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockRouteRepository extends Mock implements RouteRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(TravelMode.driving);
  });

  group('MapRouteNotifier Tests', () {
    late MockRouteRepository mockRepository;

    setUp(() {
      mockRepository = MockRouteRepository();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          routeRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('初期状態は MapRouteState.initial であること', () {
      final container = createContainer();
      final state = container.read(mapRouteProvider);
      check(state).isA<MapRouteStateInitial>();
    });

    test('searchRoute 成功時に MapRouteState.success に遷移すること', () async {
      const origin = LatLng(35.681236, 139.767125);
      const destination = LatLng(35.6585805, 139.7454329);
      const sampleRoute = MapRoute(
        id: 'route_test',
        origin: origin,
        destination: destination,
        points: [origin, destination],
        distanceMeters: 3500,
        durationSeconds: 350,
        destinationName: '東京タワー',
      );

      when(
        () => mockRepository.calculateRoute(
          origin: origin,
          destination: destination,
          destinationName: '東京タワー',
          travelMode: any(named: 'travelMode'),
        ),
      ).thenAnswer((_) async => sampleRoute);

      final container = createContainer()..listen(mapRouteProvider, (_, _) {});
      final notifier = container.read(mapRouteProvider.notifier);

      await notifier.searchRoute(
        origin: origin,
        destination: destination,
        destinationName: '東京タワー',
      );

      final state = container.read(mapRouteProvider);
      check(state).isA<MapRouteStateSuccess>();
      final success = state as MapRouteStateSuccess;
      check(success.route.id).equals('route_test');
      check(success.route.destinationName).equals('東京タワー');
    });

    test('searchRoute に travelMode を指定した場合にリポジトリへ正しく渡されること', () async {
      const origin = LatLng(35.681236, 139.767125);
      const destination = LatLng(35.6585805, 139.7454329);
      const sampleRoute = MapRoute(
        id: 'route_walking_test',
        origin: origin,
        destination: destination,
        points: [origin, destination],
        distanceMeters: 3000,
        durationSeconds: 2400,
        travelMode: TravelMode.walking,
      );

      when(
        () => mockRepository.calculateRoute(
          origin: origin,
          destination: destination,
          destinationName: any(named: 'destinationName'),
          travelMode: TravelMode.walking,
        ),
      ).thenAnswer((_) async => sampleRoute);

      final container = createContainer()..listen(mapRouteProvider, (_, _) {});
      final notifier = container.read(mapRouteProvider.notifier);

      await notifier.searchRoute(
        origin: origin,
        destination: destination,
        travelMode: TravelMode.walking,
      );

      final state = container.read(mapRouteProvider);
      check(state).isA<MapRouteStateSuccess>();
      final success = state as MapRouteStateSuccess;
      check(success.route.travelMode).equals(TravelMode.walking);
      verify(
        () => mockRepository.calculateRoute(
          origin: origin,
          destination: destination,
          travelMode: TravelMode.walking,
        ),
      ).called(1);
    });

    test('searchRoute 例外発生時に MapRouteState.error に遷移すること', () async {
      const origin = LatLng(35.681236, 139.767125);
      const destination = LatLng(35.6585805, 139.7454329);

      when(
        () => mockRepository.calculateRoute(
          origin: origin,
          destination: destination,
          destinationName: any(named: 'destinationName'),
          travelMode: any(named: 'travelMode'),
        ),
      ).thenThrow(Exception('Route calculation error'));

      final container = createContainer()..listen(mapRouteProvider, (_, _) {});
      final notifier = container.read(mapRouteProvider.notifier);

      await notifier.searchRoute(
        origin: origin,
        destination: destination,
      );

      final state = container.read(mapRouteProvider);
      check(state).isA<MapRouteStateError>();
    });

    test('clearRoute 実行時に初期状態に戻ること', () async {
      const origin = LatLng(35.681236, 139.767125);
      const destination = LatLng(35.6585805, 139.7454329);
      const sampleRoute = MapRoute(
        id: 'route_test',
        origin: origin,
        destination: destination,
        points: [origin, destination],
        distanceMeters: 3500,
        durationSeconds: 350,
      );

      when(
        () => mockRepository.calculateRoute(
          origin: origin,
          destination: destination,
          destinationName: any(named: 'destinationName'),
          travelMode: any(named: 'travelMode'),
        ),
      ).thenAnswer((_) async => sampleRoute);

      final container = createContainer()..listen(mapRouteProvider, (_, _) {});
      final notifier = container.read(mapRouteProvider.notifier);

      await notifier.searchRoute(
        origin: origin,
        destination: destination,
      );

      check(container.read(mapRouteProvider)).isA<MapRouteStateSuccess>();

      notifier.clearRoute();
      check(container.read(mapRouteProvider)).isA<MapRouteStateInitial>();
    });

    test(
      'searchRoute 実行中に clearRoute が呼ばれた場合、非同期完了後に initial 状態が維持されること',
      () async {
        const origin = LatLng(35.681236, 139.767125);
        const destination = LatLng(35.6585805, 139.7454329);
        const sampleRoute = MapRoute(
          id: 'route_test',
          origin: origin,
          destination: destination,
          points: [origin, destination],
          distanceMeters: 3500,
          durationSeconds: 350,
        );

        final completer = Completer<MapRoute>();

        when(
          () => mockRepository.calculateRoute(
            origin: origin,
            destination: destination,
            destinationName: any(named: 'destinationName'),
            travelMode: any(named: 'travelMode'),
          ),
        ).thenAnswer((_) => completer.future);

        final container = createContainer()
          ..listen(mapRouteProvider, (_, _) {});
        final notifier = container.read(mapRouteProvider.notifier);

        final searchFuture = notifier.searchRoute(
          origin: origin,
          destination: destination,
        );

        check(container.read(mapRouteProvider)).isA<MapRouteStateLoading>();

        // 検索完了前に案内を終了
        notifier.clearRoute();
        check(container.read(mapRouteProvider)).isA<MapRouteStateInitial>();

        // 非同期計算を完了させる
        completer.complete(sampleRoute);
        await searchFuture;

        // 古いリクエストは破棄され、initial のままであること
        check(container.read(mapRouteProvider)).isA<MapRouteStateInitial>();
      },
    );

    test('複数の searchRoute が並行実行された場合、最新の検索結果のみが反映されること', () async {
      const origin = LatLng(35.681236, 139.767125);
      const destination1 = LatLng(35.6585805, 139.7454329);
      const destination2 = LatLng(35.670000, 139.750000);
      const route1 = MapRoute(
        id: 'route_1',
        origin: origin,
        destination: destination1,
        points: [origin, destination1],
        distanceMeters: 1000,
        durationSeconds: 100,
        destinationName: 'スポット1',
      );
      const route2 = MapRoute(
        id: 'route_2',
        origin: origin,
        destination: destination2,
        points: [origin, destination2],
        distanceMeters: 2000,
        durationSeconds: 200,
        destinationName: 'スポット2',
      );

      final completer1 = Completer<MapRoute>();
      final completer2 = Completer<MapRoute>();

      when(
        () => mockRepository.calculateRoute(
          origin: origin,
          destination: destination1,
          destinationName: 'スポット1',
          travelMode: any(named: 'travelMode'),
        ),
      ).thenAnswer((_) => completer1.future);

      when(
        () => mockRepository.calculateRoute(
          origin: origin,
          destination: destination2,
          destinationName: 'スポット2',
          travelMode: any(named: 'travelMode'),
        ),
      ).thenAnswer((_) => completer2.future);

      final container = createContainer()..listen(mapRouteProvider, (_, _) {});
      final notifier = container.read(mapRouteProvider.notifier);

      // 1回目の検索開始
      final future1 = notifier.searchRoute(
        origin: origin,
        destination: destination1,
        destinationName: 'スポット1',
      );

      // 2回目の検索開始（最新）
      final future2 = notifier.searchRoute(
        origin: origin,
        destination: destination2,
        destinationName: 'スポット2',
      );

      // 2回目（最新）が先に完了
      completer2.complete(route2);
      await future2;

      check(container.read(mapRouteProvider)).isA<MapRouteStateSuccess>();
      final success2 = container.read(mapRouteProvider) as MapRouteStateSuccess;
      check(success2.route.id).equals('route_2');

      // 遅れて1回目（古い）が完了しても上書きされないこと
      completer1.complete(route1);
      await future1;

      final successFinal =
          container.read(mapRouteProvider) as MapRouteStateSuccess;
      check(successFinal.route.id).equals('route_2');
    });

    test(
      'searchRoute 実行中に clearRoute され非同期計算で例外が起きた場合でも error に遷移しないこと',
      () async {
        const origin = LatLng(35.681236, 139.767125);
        const destination = LatLng(35.6585805, 139.7454329);

        final completer = Completer<MapRoute>();

        when(
          () => mockRepository.calculateRoute(
            origin: origin,
            destination: destination,
            destinationName: any(named: 'destinationName'),
            travelMode: any(named: 'travelMode'),
          ),
        ).thenAnswer((_) => completer.future);

        final container = createContainer()
          ..listen(mapRouteProvider, (_, _) {});
        final notifier = container.read(mapRouteProvider.notifier);

        final searchFuture = notifier.searchRoute(
          origin: origin,
          destination: destination,
        );

        notifier.clearRoute();
        check(container.read(mapRouteProvider)).isA<MapRouteStateInitial>();

        completer.completeError(Exception('遅延エラー'));
        await searchFuture;

        check(container.read(mapRouteProvider)).isA<MapRouteStateInitial>();
      },
    );
  });
}
