import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/map/application/map_notifier.dart';
import 'package:flutter_sample/src/features/map/domain/location_state.dart';
import 'package:flutter_sample/src/features/map/presentation/map_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// 🗺️ GoogleMaps のプラットフォームチャネルのモッククラス
class MockGoogleMapsPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GoogleMapsFlutterPlatform {
  bool animateCameraCalled = false;
  final Set<int> _initializedMaps = {};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final memberName = invocation.memberName.toString();
    if (memberName.contains('Symbol("on')) {
      return const Stream<Never>.empty();
    }
    if (memberName.contains('Symbol("animate')) {
      animateCameraCalled = true;
      return Future<void>.value();
    }
    if (memberName.contains('Symbol("update') ||
        memberName.contains('Symbol("clear')) {
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }

  @override
  Future<void> init(int mapId) async {}

  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapObjects mapObjects = const MapObjects(),
    MapConfiguration mapConfiguration = const MapConfiguration(),
  }) {
    if (!_initializedMaps.contains(creationId)) {
      _initializedMaps.add(creationId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPlatformViewCreated(creationId);
      });
    }
    return const SizedBox();
  }
}

class MockTalker extends Mock implements Talker {}

void main() {
  late MockGoogleMapsPlatform mockMapsPlatform;
  late MockTalker mockTalker;

  setUp(() {
    mockMapsPlatform = MockGoogleMapsPlatform();
    mockTalker = MockTalker();
    GoogleMapsFlutterPlatform.instance = mockMapsPlatform;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/google_maps_0'),
          (methodCall) async {
            return null;
          },
        );
  });

  Widget createTestWidget({
    required Widget child,
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        loggerProvider.overrideWithValue(mockTalker),
        ...overrides,
      ].cast(),
      child: MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('MapScreen Widget Tests', () {
    testWidgets('MapScreen が正しく描画され、現在地移動 FAB が表示されること', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
        ),
      );
      await tester.pump();

      check(find.byType(MapScreen)).findsOne();
      check(find.byKey(const Key('fetchLocationFab'))).findsOne();
    });

    testWidgets('現在地取得中に CircularProgressIndicator が表示されること', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapProvider.overrideWith(
              () => _TestMapNotifier(const LocationState.loading()),
            ),
          ],
        ),
      );
      await tester.pump();

      check(find.byType(CircularProgressIndicator)).findsOne();
    });

    testWidgets('FAB をタップすると fetchCurrentLocation が呼ばれること', (tester) async {
      late _TestMapNotifier testNotifier;
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapProvider.overrideWith(
              () => testNotifier = _TestMapNotifier(
                const LocationState.initial(),
              ),
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('fetchLocationFab')));
      await tester.pump();

      check(testNotifier.fetchCurrentLocationCalled).isTrue();
    });

    testWidgets('permissionDenied 状態時に SnackBar が表示されること', (tester) async {
      late _TestMapNotifier testNotifier;
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapProvider.overrideWith(
              () => testNotifier = _TestMapNotifier(
                const LocationState.initial(),
              ),
            ),
          ],
        ),
      );
      await tester.pump();

      testNotifier.currentState = const LocationState.permissionDenied();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      check(find.byType(SnackBar)).findsOne();
    });

    testWidgets(
      'permissionDeniedForever 状態時に SnackBar と設定ボタンが表示され、 '
      'タップすると openAppSettings が呼ばれること',
      (tester) async {
        late _TestMapNotifier testNotifier;
        await tester.pumpWidget(
          createTestWidget(
            child: const MapScreen(),
            overrides: [
              mapProvider.overrideWith(
                () => testNotifier = _TestMapNotifier(
                  const LocationState.initial(),
                ),
              ),
            ],
          ),
        );
        await tester.pump();

        testNotifier.currentState =
            const LocationState.permissionDeniedForever();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        check(find.byType(SnackBar)).findsOne();
        final actionFinder = find.widgetWithText(SnackBarAction, '設定を開く');
        check(actionFinder).findsOne();

        await tester.tap(actionFinder);
        await tester.pump();

        check(testNotifier.openAppSettingsCalled).isTrue();
      },
    );

    testWidgets(
      'serviceDisabled 状態時に SnackBar と設定ボタンが表示され、 '
      'タップすると openLocationSettings が呼ばれること',
      (tester) async {
        late _TestMapNotifier testNotifier;
        await tester.pumpWidget(
          createTestWidget(
            child: const MapScreen(),
            overrides: [
              mapProvider.overrideWith(
                () => testNotifier = _TestMapNotifier(
                  const LocationState.initial(),
                ),
              ),
            ],
          ),
        );
        await tester.pump();

        testNotifier.currentState = const LocationState.serviceDisabled();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        check(find.byType(SnackBar)).findsOne();
        final actionFinder = find.widgetWithText(SnackBarAction, '設定を開く');
        check(actionFinder).findsOne();

        await tester.tap(actionFinder);
        await tester.pump();

        check(testNotifier.openLocationSettingsCalled).isTrue();
      },
    );

    testWidgets('error 状態時に エラー SnackBar が表示されること', (tester) async {
      late _TestMapNotifier testNotifier;
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapProvider.overrideWith(
              () => testNotifier = _TestMapNotifier(
                const LocationState.initial(),
              ),
            ),
          ],
        ),
      );
      await tester.pump();

      testNotifier.currentState = const LocationState.error('Map error');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      check(find.byType(SnackBar)).findsOne();
    });

    testWidgets('success 状態時に カメラアニメーション移動が実行されること', (tester) async {
      late _TestMapNotifier testNotifier;
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapProvider.overrideWith(
              () => testNotifier = _TestMapNotifier(
                const LocationState.initial(),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      final position = Position(
        longitude: 139.767125,
        latitude: 35.681236,
        timestamp: DateTime(2026, 8, 11),
        accuracy: 5,
        altitude: 10,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );

      testNotifier.currentState = LocationState.success(position);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      check(mockMapsPlatform.animateCameraCalled).isTrue();
    });
  });
}

class _TestMapNotifier extends MapNotifier {
  _TestMapNotifier(this._initialState);

  final LocationState _initialState;

  bool fetchCurrentLocationCalled = false;
  bool openAppSettingsCalled = false;
  bool openLocationSettingsCalled = false;

  @override
  LocationState build() {
    return _initialState;
  }

  LocationState get currentState => state;

  set currentState(LocationState newState) {
    state = newState;
  }

  @override
  Future<void> fetchCurrentLocation() async {
    fetchCurrentLocationCalled = true;
  }

  @override
  Future<void> openAppSettings() async {
    openAppSettingsCalled = true;
  }

  @override
  Future<void> openLocationSettings() async {
    openLocationSettingsCalled = true;
  }
}
