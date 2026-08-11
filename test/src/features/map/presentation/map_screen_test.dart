import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/map/application/map_notifier.dart';
import 'package:flutter_sample/src/features/map/application/map_search_notifier.dart';
import 'package:flutter_sample/src/features/map/domain/location_candidate.dart';
import 'package:flutter_sample/src/features/map/domain/location_state.dart';
import 'package:flutter_sample/src/features/map/domain/map_search_state.dart';
import 'package:flutter_sample/src/features/map/presentation/map_screen.dart';
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
      );
      const candidate2 = LocationCandidate(
        latitude: 35.681500,
        longitude: 139.767200,
        name: '東京駅 (メトロ)',
        address: '東京都千代田区丸の内一丁目4-1',
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
