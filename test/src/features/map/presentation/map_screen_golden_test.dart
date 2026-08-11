import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sample/src/features/map/presentation/map_screen.dart';
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
  });
}
