import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/map/domain/map_route.dart';
import 'package:flutter_sample/src/features/map/domain/travel_mode.dart';
import 'package:flutter_sample/src/features/map/presentation/widgets/route_navigation_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('RouteNavigationCard Tests', () {
    testWidgets('目的地名・距離・所要時間が正しく描画され、閉じるボタンが動作すること', (tester) async {
      var closePressed = false;
      const sampleRoute = MapRoute(
        id: 'route_card_test',
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
        MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: RouteNavigationCard(
              route: sampleRoute,
              onClose: () {
                closePressed = true;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      check(find.text('東京タワー')).findsOne();
      check(find.text('3.5 km')).findsOne();
      check(find.text('6分')).findsOne();

      final closeButtonFinder = find.byKey(
        const Key('routeNavigationCloseButton'),
      );
      check(closeButtonFinder).findsOne();

      await tester.tap(closeButtonFinder);
      await tester.pump();

      check(closePressed).isTrue();
    });

    testWidgets('目的地名が未設定の場合、デフォルトのタイトルが表示されること', (tester) async {
      const sampleRoute = MapRoute(
        id: 'route_card_test_no_title',
        origin: LatLng(35.681236, 139.767125),
        destination: LatLng(35.6585805, 139.7454329),
        points: [
          LatLng(35.681236, 139.767125),
          LatLng(35.6585805, 139.7454329),
        ],
        distanceMeters: 1200,
        durationSeconds: 120,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: RouteNavigationCard(
              route: sampleRoute,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      check(find.text('ルート案内')).findsOne();
    });

    testWidgets('移動手段切り替えボタンが表示され、タップ時に onTravelModeChanged が呼ばれること', (
      tester,
    ) async {
      TravelMode? changedMode;
      const sampleRoute = MapRoute(
        id: 'route_card_mode_test',
        origin: LatLng(35.681236, 139.767125),
        destination: LatLng(35.6585805, 139.7454329),
        points: [
          LatLng(35.681236, 139.767125),
          LatLng(35.6585805, 139.7454329),
        ],
        distanceMeters: 3500,
        durationSeconds: 360,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: RouteNavigationCard(
              route: sampleRoute,
              onClose: () {},
              onTravelModeChanged: (mode) {
                changedMode = mode;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // 各移動手段のラベルが表示されていること
      check(find.text('車')).findsOne();
      check(find.text('徒歩')).findsOne();
      check(find.text('自転車')).findsOne();
      check(find.text('公共交通')).findsOne();

      // 「徒歩」をタップ
      await tester.tap(find.text('徒歩'));
      await tester.pump();

      check(changedMode).equals(TravelMode.walking);
    });
  });
}
