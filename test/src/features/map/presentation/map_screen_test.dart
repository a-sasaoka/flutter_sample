import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/map/application/map_notifier.dart';
import 'package:flutter_sample/src/features/map/application/map_route_notifier.dart';
import 'package:flutter_sample/src/features/map/application/map_search_notifier.dart';
import 'package:flutter_sample/src/features/map/data/spot_repository.dart';
import 'package:flutter_sample/src/features/map/domain/location_candidate.dart';
import 'package:flutter_sample/src/features/map/domain/location_state.dart';
import 'package:flutter_sample/src/features/map/domain/map_route.dart';
import 'package:flutter_sample/src/features/map/domain/map_route_state.dart';
import 'package:flutter_sample/src/features/map/domain/map_search_state.dart';
import 'package:flutter_sample/src/features/map/domain/map_spot.dart';
import 'package:flutter_sample/src/features/map/domain/travel_mode.dart';
import 'package:flutter_sample/src/features/map/presentation/map_screen.dart';
import 'package:flutter_sample/src/features/map/presentation/widgets/route_navigation_card.dart';
import 'package:flutter_sample/src/features/map/presentation/widgets/spot_detail_bottom_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  CameraUpdate? lastCameraUpdate;
  bool autoCreatePlatformView = true;
  PlatformViewCreatedCallback? pendingOnPlatformViewCreated;
  int? pendingCreationId;
  final Set<int> _initializedMaps = {};

  void triggerOnPlatformViewCreated(int id) {
    if (pendingOnPlatformViewCreated != null) {
      _initializedMaps.add(id);
      pendingOnPlatformViewCreated!(id);
      pendingOnPlatformViewCreated = null;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final memberName = invocation.memberName.toString();
    if (memberName.contains('Symbol("on')) {
      return const Stream<Never>.empty();
    }
    if (memberName.contains('Symbol("animate')) {
      animateCameraCalled = true;
      for (final arg in invocation.positionalArguments) {
        if (arg is CameraUpdate) {
          lastCameraUpdate = arg;
          break;
        }
      }
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
      if (autoCreatePlatformView) {
        _initializedMaps.add(creationId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onPlatformViewCreated(creationId);
        });
      } else {
        pendingCreationId = creationId;
        pendingOnPlatformViewCreated = onPlatformViewCreated;
      }
    }
    return const SizedBox();
  }
}

class MockTalker extends Mock implements Talker {}

class FakeSpotRepository implements SpotRepository {
  @override
  Future<List<MapSpot>> getSpots() async => [];

  @override
  Future<MapSpot?> getSpotById(String id) async => null;
}

class FakeSpotRepositoryWithData implements SpotRepository {
  @override
  Future<List<MapSpot>> getSpots() async => SpotRepositoryImpl.sampleSpots;

  @override
  Future<MapSpot?> getSpotById(String id) async =>
      SpotRepositoryImpl.sampleSpots.firstWhere((spot) => spot.id == id);
}

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
    final defaultOverrides = <dynamic>[
      loggerProvider.overrideWithValue(mockTalker),
      spotRepositoryProvider.overrideWithValue(FakeSpotRepository()),
    ];

    final customOrigins = overrides.map((o) => (o as dynamic).origin).toSet();
    final filteredDefaults = defaultOverrides.where(
      (d) => !customOrigins.contains((d as dynamic).origin),
    );

    return ProviderScope(
      overrides: [
        ...filteredDefaults,
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
    test('MapScreen can be instantiated', () {
      /// カバレッジ計測でコンストラクタ実行をヒットさせるため非const呼び出しを許可します。
      // ignore: prefer_const_constructors
      final screen = MapScreen();
      check(screen).isA<MapScreen>();
    });

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

    testWidgets(
      'コントローラ未生成時に LocationState.success を受信した場合、 pendingPositionState に保持され、 '
      'onMapCreated 時にカメラ移動が実行されること',
      (tester) async {
        mockMapsPlatform.autoCreatePlatformView = false;
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

        // コントローラ未生成(null)の状態で success に遷移 -> pendingPositionState に保存される (L55)
        testNotifier.currentState = LocationState.success(position);
        await tester.pump();

        check(mockMapsPlatform.animateCameraCalled).isFalse();

        // 後から onPlatformViewCreated が発火
        // -> 保留中の位置情報でカメラ移動実行 (L118-L133)
        mockMapsPlatform.triggerOnPlatformViewCreated(0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        check(mockMapsPlatform.animateCameraCalled).isTrue();
      },
    );

    testWidgets('検索バーにテキストを入力し送信ボタンをタップすると searchLocation が実行されること', (
      tester,
    ) async {
      late _TestMapSearchNotifier testSearchNotifier;
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapSearchProvider.overrideWith(
              () => testSearchNotifier = _TestMapSearchNotifier(
                const MapSearchState.initial(),
              ),
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('mapSearchTextField')),
        '東京タワー',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('mapSearchButton')));
      await tester.pump();

      check(testSearchNotifier.searchLocationQuery).equals('東京タワー');
      final editableText1 = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      check(editableText1.focusNode.hasFocus).isFalse();
    });

    testWidgets('検索バーでキーボードの検索キーを押すと searchLocation が実行されること', (
      tester,
    ) async {
      late _TestMapSearchNotifier testSearchNotifier;
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapSearchProvider.overrideWith(
              () => testSearchNotifier = _TestMapSearchNotifier(
                const MapSearchState.initial(),
              ),
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('mapSearchTextField')),
        'スカイツリー',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      check(testSearchNotifier.searchLocationQuery).equals('スカイツリー');
      final searchContext2 = tester.element(
        find.byKey(const Key('mapSearchTextField')),
      );
      check(FocusScope.of(searchContext2).focusedChild).isNull();
      final editableText2 = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      check(editableText2.focusNode.hasFocus).isFalse();
    });

    testWidgets('クリアボタンをタップするとテキストと検索状態がクリアされること', (tester) async {
      late _TestMapSearchNotifier testSearchNotifier;
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapSearchProvider.overrideWith(
              () => testSearchNotifier = _TestMapSearchNotifier(
                const MapSearchState.initial(),
              ),
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('mapSearchTextField')),
        '渋谷',
      );
      await tester.pump();

      final clearButtonFinder = find.byKey(const Key('mapSearchClearButton'));
      check(clearButtonFinder).findsOne();
      check(find.byTooltip('検索をクリア')).findsOne();

      await tester.tap(clearButtonFinder);
      await tester.pump();

      check(testSearchNotifier.clearSearchCalled).isTrue();
      final textField = tester.widget<TextField>(
        find.byKey(const Key('mapSearchTextField')),
      );
      check(textField.controller?.text).equals('');
    });

    testWidgets('単一検索成功 (success) 時にカメラ移動が実行されること', (tester) async {
      late _TestMapSearchNotifier testSearchNotifier;
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapSearchProvider.overrideWith(
              () => testSearchNotifier = _TestMapSearchNotifier(
                const MapSearchState.initial(),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      const candidate = LocationCandidate(
        latitude: 35.681236,
        longitude: 139.767125,
        name: '東京駅',
        address: '東京都千代田区丸の内一丁目',
      );

      testSearchNotifier.currentState = const MapSearchState.success(
        locations: [candidate],
        query: '東京駅',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      check(mockMapsPlatform.animateCameraCalled).isTrue();
    });

    testWidgets('複数検索成功 (success) 時に候補選択ボトムシートが表示され、タップした候補地へ移動すること', (
      tester,
    ) async {
      late _TestMapSearchNotifier testSearchNotifier;
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapSearchProvider.overrideWith(
              () => testSearchNotifier = _TestMapSearchNotifier(
                const MapSearchState.initial(),
              ),
            ),
          ],
        ),
      );
      await tester.pump();

      const candidate1 = LocationCandidate(
        latitude: 35.681236,
        longitude: 139.767125,
        name: '東京駅 (JR)',
        address: '東京都千代田区丸の内一丁目',
        rating: 4.8,
      );
      const candidate2 = LocationCandidate(
        latitude: 35.681500,
        longitude: 139.767200,
        name: '東京駅 (メトロ)',
      );

      testSearchNotifier.currentState = const MapSearchState.success(
        locations: [candidate1, candidate2],
        query: '東京駅',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      // ボトムシート内の候補が描画されていることをアサート
      check(find.text('検索結果を選択')).findsOne();
      check(find.byKey(const Key('mapCandidateTile_0'))).findsOne();
      check(find.byKey(const Key('mapCandidateTile_1'))).findsOne();
      check(find.byIcon(Icons.star)).findsOne();
      check(find.text('4.8')).findsOne();

      // 2つ目の候補をタップ
      await tester.tap(find.byKey(const Key('mapCandidateTile_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      check(mockMapsPlatform.animateCameraCalled).isTrue();
    });

    testWidgets(
      'コントローラ未生成時に単一検索成功 (success) を受信した場合、 '
      'pendingLatLngState に保持され onMapCreated 時にカメラ移動が実行されること',
      (tester) async {
        mockMapsPlatform.autoCreatePlatformView = false;
        late _TestMapSearchNotifier testSearchNotifier;
        const candidate = LocationCandidate(
          latitude: 35.681236,
          longitude: 139.767125,
          name: '東京駅',
        );

        await tester.pumpWidget(
          createTestWidget(
            child: const MapScreen(),
            overrides: [
              mapSearchProvider.overrideWith(
                () => testSearchNotifier = _TestMapSearchNotifier(
                  const MapSearchState.initial(),
                ),
              ),
            ],
          ),
        );
        await tester.pump();

        testSearchNotifier.currentState = const MapSearchState.success(
          locations: [candidate],
          query: '東京駅',
        );
        await tester.pump();

        final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
        check(googleMap.markers.length).equals(1);

        check(mockMapsPlatform.animateCameraCalled).isFalse();

        mockMapsPlatform.triggerOnPlatformViewCreated(0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        check(mockMapsPlatform.animateCameraCalled).isTrue();
      },
    );

    testWidgets(
      'コントローラ未生成時に複数候補ボトムシートで候補をタップした場合、 '
      'pendingLatLngState に保持され onMapCreated 時にカメラ移動が実行されること',
      (tester) async {
        mockMapsPlatform.autoCreatePlatformView = false;
        late _TestMapSearchNotifier testSearchNotifier;
        const candidate1 = LocationCandidate(
          latitude: 35.681236,
          longitude: 139.767125,
          name: '東京駅 (JR)',
        );
        const candidate2 = LocationCandidate(
          latitude: 35.681500,
          longitude: 139.767200,
          name: '東京駅 (メトロ)',
        );

        await tester.pumpWidget(
          createTestWidget(
            child: const MapScreen(),
            overrides: [
              mapSearchProvider.overrideWith(
                () => testSearchNotifier = _TestMapSearchNotifier(
                  const MapSearchState.initial(),
                ),
              ),
            ],
          ),
        );
        await tester.pump();

        testSearchNotifier.currentState = const MapSearchState.success(
          locations: [candidate1, candidate2],
          query: '東京駅',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        // 2つ目の候補をタップ
        await tester.tap(find.byKey(const Key('mapCandidateTile_1')));
        await tester.pump();

        check(mockMapsPlatform.animateCameraCalled).isFalse();

        mockMapsPlatform.triggerOnPlatformViewCreated(0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        check(mockMapsPlatform.animateCameraCalled).isTrue();
        check(mockMapsPlatform.lastCameraUpdate).isNotNull();
        final cameraUpdateJson = mockMapsPlatform.lastCameraUpdate!
            .toJson()
            .toString();
        check(cameraUpdateJson).contains(candidate2.latitude.toString());
        check(cameraUpdateJson).contains(candidate2.longitude.toString());
      },
    );

    testWidgets('検索該当なし (empty) 時に SnackBar が表示されること', (tester) async {
      late _TestMapSearchNotifier testSearchNotifier;
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapSearchProvider.overrideWith(
              () => testSearchNotifier = _TestMapSearchNotifier(
                const MapSearchState.initial(),
              ),
            ),
          ],
        ),
      );
      await tester.pump();

      testSearchNotifier.currentState = const MapSearchState.empty(
        query: '不明な場所',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      check(find.byType(SnackBar)).findsOne();
    });

    testWidgets('MapScreen に Key を指定して正常にインスタンス化できること', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(key: Key('test_map_key')),
        ),
      );
      await tester.pump();
      check(find.byKey(const Key('test_map_key'))).findsOne();
    });

    testWidgets(
      '検索中 (loading) 時に SearchBar 内に CircularProgressIndicator が表示されること',
      (
        tester,
      ) async {
        late _TestMapSearchNotifier testSearchNotifier;
        await tester.pumpWidget(
          createTestWidget(
            child: const MapScreen(),
            overrides: [
              mapSearchProvider.overrideWith(
                () => testSearchNotifier = _TestMapSearchNotifier(
                  const MapSearchState.initial(),
                ),
              ),
            ],
          ),
        );
        await tester.pump();

        testSearchNotifier.currentState = const MapSearchState.loading();
        await tester.pump();

        check(find.byType(CircularProgressIndicator)).findsAtLeast(1);
      },
    );

    testWidgets('検索エラー (error) 時に エラー SnackBar が表示されること', (tester) async {
      late _TestMapSearchNotifier testSearchNotifier;
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapSearchProvider.overrideWith(
              () => testSearchNotifier = _TestMapSearchNotifier(
                const MapSearchState.initial(),
              ),
            ),
          ],
        ),
      );
      await tester.pump();

      testSearchNotifier.currentState = const MapSearchState.error(
        '検索エラーメッセージ',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      check(find.byType(SnackBar)).findsOne();
    });

    testWidgets('spotProvider のデータ読み込みが完了して MapScreen が描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            spotRepositoryProvider.overrideWithValue(
              FakeSpotRepositoryWithData(),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      check(find.byType(MapScreen)).findsOne();
    });

    testWidgets('スポットマーカーをタップするとカメラ移動と SpotDetailBottomSheet が表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            spotRepositoryProvider.overrideWithValue(
              FakeSpotRepositoryWithData(),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      mockMapsPlatform.triggerOnPlatformViewCreated(0);
      await tester.pump();

      final googleMapFinder = find.byType(GoogleMap);
      check(googleMapFinder).findsOne();
      final googleMap = tester.widget<GoogleMap>(googleMapFinder);

      final spotMarker = googleMap.markers.firstWhere(
        (marker) => marker.markerId.value.startsWith('spot_'),
      );

      check(spotMarker.onTap).isNotNull();
      spotMarker.onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      check(find.byType(SpotDetailBottomSheet)).findsOne();
      check(mockMapsPlatform.animateCameraCalled).isTrue();
    });

    testWidgets(
      'コントローラ未生成時にスポットマーカーをタップした場合でも SpotDetailBottomSheet が表示されること',
      (
        tester,
      ) async {
        mockMapsPlatform.autoCreatePlatformView = false;
        await tester.pumpWidget(
          createTestWidget(
            child: const MapScreen(),
            overrides: [
              spotRepositoryProvider.overrideWithValue(
                FakeSpotRepositoryWithData(),
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();

        final googleMapFinder = find.byType(GoogleMap);
        check(googleMapFinder).findsOne();
        final googleMap = tester.widget<GoogleMap>(googleMapFinder);

        final spotMarker = googleMap.markers.firstWhere(
          (marker) => marker.markerId.value.startsWith('spot_'),
        );

        check(spotMarker.onTap).isNotNull();
        spotMarker.onTap!();
        await tester.pump();

        check(mockMapsPlatform.animateCameraCalled).isFalse();
        check(find.byType(SpotDetailBottomSheet)).findsOne();
      },
    );

    testWidgets(
      'ルート検索成功 (success) 時に Polyline と RouteNavigationCard が表示されカメラが境界移動すること',
      (tester) async {
        late _TestMapRouteNotifier testRouteNotifier;
        const sampleRoute = MapRoute(
          id: 'test_route_1',
          origin: LatLng(35.681236, 139.767125),
          destination: LatLng(35.6585805, 139.7454329),
          points: [
            LatLng(35.681236, 139.767125),
            LatLng(35.6585805, 139.7454329),
          ],
          distanceMeters: 3500,
          durationSeconds: 360,
          destinationName: '東京タワー',
        );

        await tester.pumpWidget(
          createTestWidget(
            child: const MapScreen(),
            overrides: [
              mapRouteProvider.overrideWith(
                () => testRouteNotifier = _TestMapRouteNotifier(
                  const MapRouteState.initial(),
                ),
              ),
            ],
          ),
        );
        await tester.pump();
        mockMapsPlatform.triggerOnPlatformViewCreated(0);
        await tester.pump();

        testRouteNotifier.currentState = const MapRouteState.success(
          sampleRoute,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        check(find.byType(RouteNavigationCard)).findsOne();
        check(find.text('東京タワー')).findsOne();
        check(mockMapsPlatform.animateCameraCalled).isTrue();

        final googleMapFinder = find.byType(GoogleMap);
        check(googleMapFinder).findsOne();
        final googleMap = tester.widget<GoogleMap>(googleMapFinder);
        check(googleMap.polylines.length).equals(1);
      },
    );

    testWidgets(
      'コントローラ未生成時にルート検索成功を受信した場合、'
      'pendingBounds に保持され onMapCreated 時にカメラ移動が実行されること',
      (tester) async {
        late _TestMapRouteNotifier testRouteNotifier;
        const sampleRoute = MapRoute(
          id: 'test_route_pending',
          origin: LatLng(35.681236, 139.767125),
          destination: LatLng(35.6585805, 139.7454329),
          points: [
            LatLng(35.681236, 139.767125),
            LatLng(35.6585805, 139.7454329),
          ],
          distanceMeters: 3500,
          durationSeconds: 360,
          destinationName: '東京タワー',
        );

        mockMapsPlatform.autoCreatePlatformView = false;
        await tester.pumpWidget(
          createTestWidget(
            child: const MapScreen(),
            overrides: [
              mapRouteProvider.overrideWith(
                () => testRouteNotifier = _TestMapRouteNotifier(
                  const MapRouteState.initial(),
                ),
              ),
            ],
          ),
        );
        await tester.pump();

        testRouteNotifier.currentState = const MapRouteState.success(
          sampleRoute,
        );
        await tester.pump();

        check(mockMapsPlatform.animateCameraCalled).isFalse();

        mockMapsPlatform.triggerOnPlatformViewCreated(0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        check(mockMapsPlatform.animateCameraCalled).isTrue();
      },
    );

    testWidgets('ルート計算中 (loading) 時に CircularProgressIndicator が表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapRouteProvider.overrideWith(
              () => _TestMapRouteNotifier(
                const MapRouteState.loading(),
              ),
            ),
          ],
        ),
      );
      await tester.pump();

      check(find.byType(CircularProgressIndicator)).findsOne();
    });

    testWidgets('ルートエラー (error) 時に SnackBar が表示されること', (tester) async {
      late _TestMapRouteNotifier testRouteNotifier;

      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapRouteProvider.overrideWith(
              () => testRouteNotifier = _TestMapRouteNotifier(
                const MapRouteState.initial(),
              ),
            ),
          ],
        ),
      );
      await tester.pump();

      testRouteNotifier.currentState = const MapRouteState.error(
        'ルート検索失敗',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      check(find.byType(SnackBar)).findsOne();

      // SnackBar の表示タイマーを完了させて後続テストへの影響を防止
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('RouteNavigationCard の閉じるボタンをタップすると clearRoute が呼ばれること', (
      tester,
    ) async {
      late _TestMapRouteNotifier testRouteNotifier;
      const sampleRoute = MapRoute(
        id: 'test_route_close',
        origin: LatLng(35.681236, 139.767125),
        destination: LatLng(35.6585805, 139.7454329),
        points: [
          LatLng(35.681236, 139.767125),
          LatLng(35.6585805, 139.7454329),
        ],
        distanceMeters: 1000,
        durationSeconds: 100,
      );

      await tester.pumpWidget(
        createTestWidget(
          child: const MapScreen(),
          overrides: [
            mapProvider.overrideWith(
              () => _TestMapNotifier(const LocationState.initial()),
            ),
            mapRouteProvider.overrideWith(
              () => testRouteNotifier = _TestMapRouteNotifier(
                const MapRouteState.initial(),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      mockMapsPlatform.triggerOnPlatformViewCreated(0);
      await tester.pump();

      testRouteNotifier.currentState = const MapRouteState.success(
        sampleRoute,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      final closeButtonFinder = find.byKey(
        const Key('routeNavigationCloseButton'),
      );
      check(closeButtonFinder).findsOne();

      final closeButton = tester.widget<IconButton>(closeButtonFinder);
      check(closeButton.onPressed).isNotNull();
      closeButton.onPressed!();
      await tester.pump();

      check(testRouteNotifier.clearRouteCalled).isTrue();
    });

    testWidgets(
      'SpotDetailBottomSheet のルート案内ボタンをタップすると searchRoute が実行されること',
      (tester) async {
        late _TestMapRouteNotifier testRouteNotifier;
        final mockPosition = Position(
          latitude: 35.658034,
          longitude: 139.701636,
          timestamp: DateTime(2026),
          accuracy: 5,
          altitude: 10,
          altitudeAccuracy: 1,
          heading: 0,
          headingAccuracy: 1,
          speed: 0,
          speedAccuracy: 1,
        );

        await tester.pumpWidget(
          createTestWidget(
            child: const MapScreen(),
            overrides: [
              mapProvider.overrideWith(
                () => _TestMapNotifier(LocationState.success(mockPosition)),
              ),
              spotRepositoryProvider.overrideWithValue(
                FakeSpotRepositoryWithData(),
              ),
              mapRouteProvider.overrideWith(
                () => testRouteNotifier = _TestMapRouteNotifier(
                  const MapRouteState.initial(),
                ),
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();

        mockMapsPlatform.triggerOnPlatformViewCreated(0);
        await tester.pump();

        final googleMapFinder = find.byType(GoogleMap);
        final googleMap = tester.widget<GoogleMap>(googleMapFinder);
        final spotMarker = googleMap.markers.firstWhere(
          (marker) => marker.markerId.value.startsWith('spot_'),
        );

        spotMarker.onTap!();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        final startRouteButtonFinder = find.byKey(
          const Key('spotDetailStartRouteButton'),
        );
        await tester.tap(startRouteButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        check(find.byType(SpotDetailBottomSheet)).findsNothing();
        check(testRouteNotifier.searchDestinationName).equals('東京タワー');
        check(
          testRouteNotifier.searchOrigin,
        ).equals(const LatLng(35.658034, 139.701636));
      },
    );

    testWidgets(
      '現在地未取得時に SpotDetailBottomSheet のルート案内ボタンをタップすると初期位置を出発地として '
      'searchRoute が実行されること',
      (tester) async {
        late _TestMapRouteNotifier testRouteNotifier;

        await tester.pumpWidget(
          createTestWidget(
            child: const MapScreen(),
            overrides: [
              mapProvider.overrideWith(
                () => _TestMapNotifier(const LocationState.initial()),
              ),
              spotRepositoryProvider.overrideWithValue(
                FakeSpotRepositoryWithData(),
              ),
              mapRouteProvider.overrideWith(
                () => testRouteNotifier = _TestMapRouteNotifier(
                  const MapRouteState.initial(),
                ),
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();

        mockMapsPlatform.triggerOnPlatformViewCreated(0);
        await tester.pump();

        final googleMapFinder = find.byType(GoogleMap);
        final googleMap = tester.widget<GoogleMap>(googleMapFinder);
        final spotMarker = googleMap.markers.firstWhere(
          (marker) => marker.markerId.value.startsWith('spot_'),
        );

        spotMarker.onTap!();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        final startRouteButtonFinder = find.byKey(
          const Key('spotDetailStartRouteButton'),
        );
        check(startRouteButtonFinder).findsOne();

        await tester.tap(startRouteButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        check(find.byType(SpotDetailBottomSheet)).findsNothing();
        check(testRouteNotifier.searchDestinationName).equals('東京タワー');
        check(
          testRouteNotifier.searchOrigin,
        ).equals(const LatLng(35.681236, 139.767125));
      },
    );

    testWidgets(
      'RouteNavigationCard の移動手段ボタンをタップすると '
      '新しい travelMode で searchRoute が再実行されること',
      (tester) async {
        late _TestMapRouteNotifier testRouteNotifier;
        const origin = LatLng(35.681236, 139.767125);
        const destination = LatLng(35.6585805, 139.7454329);
        const initialRoute = MapRoute(
          id: 'route_mode_switch_test',
          origin: origin,
          destination: destination,
          points: [origin, destination],
          distanceMeters: 3500,
          durationSeconds: 360,
          destinationName: '東京タワー',
        );

        await tester.pumpWidget(
          createTestWidget(
            child: const MapScreen(),
            overrides: [
              mapRouteProvider.overrideWith(
                () => testRouteNotifier = _TestMapRouteNotifier(
                  const MapRouteState.success(initialRoute),
                ),
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();

        final cardFinder = find.byType(RouteNavigationCard);
        check(cardFinder).findsOne();

        final card = tester.widget<RouteNavigationCard>(cardFinder);
        check(card.onTravelModeChanged).isNotNull();

        // 異なる移動手段（徒歩）を選択した場合は再検索が実行されること
        card.onTravelModeChanged!(TravelMode.walking);
        await tester.pump();

        check(testRouteNotifier.searchTravelMode).equals(TravelMode.walking);
        check(testRouteNotifier.searchDestinationName).equals('東京タワー');

        // 現在と同じ移動手段（車）を選択した場合は再検索されないこと
        testRouteNotifier.searchTravelMode = null;
        card.onTravelModeChanged!(TravelMode.driving);
        await tester.pump();

        check(testRouteNotifier.searchTravelMode).isNull();
      },
    );
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

class _TestMapSearchNotifier extends MapSearchNotifier {
  _TestMapSearchNotifier(this._initialState);

  final MapSearchState _initialState;
  String? searchLocationQuery;
  bool clearSearchCalled = false;

  @override
  MapSearchState build() => _initialState;

  MapSearchState get currentState => state;

  set currentState(MapSearchState newState) {
    state = newState;
  }

  @override
  Future<void> searchLocation(String query) async {
    searchLocationQuery = query;
  }

  @override
  void clearSearch() {
    clearSearchCalled = true;
    state = const MapSearchState.initial();
  }
}

class _TestMapRouteNotifier extends MapRouteNotifier {
  _TestMapRouteNotifier(this._initialState);

  final MapRouteState _initialState;
  bool clearRouteCalled = false;
  LatLng? searchOrigin;
  LatLng? searchDestination;
  String? searchDestinationName;
  TravelMode? searchTravelMode;

  @override
  MapRouteState build() => _initialState;

  MapRouteState get currentState => state;

  set currentState(MapRouteState newState) {
    state = newState;
  }

  @override
  Future<void> searchRoute({
    required LatLng origin,
    required LatLng destination,
    String? destinationName,
    TravelMode travelMode = TravelMode.driving,
  }) async {
    searchOrigin = origin;
    searchDestination = destination;
    searchDestinationName = destinationName;
    searchTravelMode = travelMode;
  }

  @override
  void clearRoute() {
    clearRouteCalled = true;
    state = const MapRouteState.initial();
  }
}
