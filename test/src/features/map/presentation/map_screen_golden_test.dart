import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sample/src/features/map/domain/map_route.dart';
import 'package:flutter_sample/src/features/map/domain/map_spot.dart';
import 'package:flutter_sample/src/features/map/presentation/map_screen.dart';
import 'package:flutter_sample/src/features/map/presentation/widgets/route_navigation_card.dart';
import 'package:flutter_sample/src/features/map/presentation/widgets/spot_detail_bottom_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../../../golden_test_helper.dart';

class MockGoogleMapsPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapObjects mapObjects = const MapObjects(),
    MapConfiguration mapConfiguration = const MapConfiguration(),
  }) {
    return const SizedBox();
  }
}

void main() {
  group('MapScreen Golden Tests', () {
    late MockGoogleMapsPlatform mockMapsPlatform;

    setUp(() {
      mockMapsPlatform = MockGoogleMapsPlatform();
      GoogleMapsFlutterPlatform.instance = mockMapsPlatform;
    });

    Widget buildMapForGolden({required ThemeMode themeMode}) {
      return ProviderScope(
        child: buildGoldenTestApp(
          home: const MapScreen(),
          themeMode: themeMode,
        ),
      );
    }

    // ignore: discarded_futures, testing framework registers tests synchronously
    goldenTest(
      'MapScreen の描画 (ライト/ダークモード)',
      fileName: 'map_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildMapForGolden(themeMode: ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildMapForGolden(themeMode: ThemeMode.dark),
            ),
          ),
        ],
      ),
    );

    const sampleSpot = MapSpot(
      id: 'spot_golden_1',
      name: '東京タワー',
      category: SpotCategory.sightseeing,
      latitude: 35.6585805,
      longitude: 139.7454329,
      address: '東京都港区芝公園4-2-8',
      description: '高さ333mの総合電波塔。メインデッキからの絶景が魅力です。',
      rating: 4.6,
    );

    // ignore: discarded_futures, testing framework registers tests synchronously
    goldenTest(
      'SpotDetailBottomSheet の描画 (ライト/ダークモード)',
      fileName: 'spot_detail_bottom_sheet',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildGoldenTestApp(
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.bottomCenter,
                    child: SpotDetailBottomSheet(
                      spot: sampleSpot,
                      onStartRoutePressed: () {},
                    ),
                  ),
                ),
                themeMode: ThemeMode.light,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildGoldenTestApp(
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.bottomCenter,
                    child: SpotDetailBottomSheet(
                      spot: sampleSpot,
                      onStartRoutePressed: () {},
                    ),
                  ),
                ),
                themeMode: ThemeMode.dark,
              ),
            ),
          ),
        ],
      ),
    );

    const sampleRoute = MapRoute(
      id: 'golden_route_1',
      origin: LatLng(35.681236, 139.767125),
      destination: LatLng(35.6585805, 139.7454329),
      points: [
        LatLng(35.681236, 139.767125),
        LatLng(35.670, 139.755),
        LatLng(35.6585805, 139.7454329),
      ],
      distanceMeters: 3500,
      durationSeconds: 360,
      destinationName: '東京タワー',
    );

    // ignore: discarded_futures, testing framework registers tests synchronously
    goldenTest(
      'RouteNavigationCard の描画 (ライト/ダークモード・詳細/コンパクト)',
      fileName: 'route_navigation_card',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Expanded - Light Mode',
            child: SizedBox(
              width: 390,
              height: 240,
              child: buildGoldenTestApp(
                home: Scaffold(
                  body: RouteNavigationCard(
                    route: sampleRoute,
                    onClose: () {},
                  ),
                ),
                themeMode: ThemeMode.light,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Expanded - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 240,
              child: buildGoldenTestApp(
                home: Scaffold(
                  body: RouteNavigationCard(
                    route: sampleRoute,
                    onClose: () {},
                  ),
                ),
                themeMode: ThemeMode.dark,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Compact - Light Mode',
            child: SizedBox(
              width: 390,
              height: 100,
              child: buildGoldenTestApp(
                home: Scaffold(
                  body: RouteNavigationCard(
                    route: sampleRoute,
                    isExpanded: false,
                    onClose: () {},
                  ),
                ),
                themeMode: ThemeMode.light,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Compact - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 100,
              child: buildGoldenTestApp(
                home: Scaffold(
                  body: RouteNavigationCard(
                    route: sampleRoute,
                    isExpanded: false,
                    onClose: () {},
                  ),
                ),
                themeMode: ThemeMode.dark,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
