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

    testWidgets('徒歩ルート時に徒歩用の警告バナーが表示されること', (tester) async {
      const walkingRoute = MapRoute(
        id: 'route_card_walking_warning',
        origin: LatLng(35.681236, 139.767125),
        destination: LatLng(35.6585805, 139.7454329),
        points: [
          LatLng(35.681236, 139.767125),
          LatLng(35.6585805, 139.7454329),
        ],
        distanceMeters: 2500,
        durationSeconds: 1800,
        travelMode: TravelMode.walking,
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
              route: walkingRoute,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      check(find.byKey(const Key('routeNavigationWarningBanner'))).findsOne();
      check(
        find.text(
          '徒歩ルートには歩道がない区間が含まれる場合があります。周囲の交通にご注意ください。',
        ),
      ).findsOne();
    });

    testWidgets('自転車ルート時に自転車用の警告バナーが表示されること', (tester) async {
      const bikingRoute = MapRoute(
        id: 'route_card_biking_warning',
        origin: LatLng(35.681236, 139.767125),
        destination: LatLng(35.6585805, 139.7454329),
        points: [
          LatLng(35.681236, 139.767125),
          LatLng(35.6585805, 139.7454329),
        ],
        distanceMeters: 3000,
        durationSeconds: 600,
        travelMode: TravelMode.bicycling,
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
              route: bikingRoute,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      check(find.byKey(const Key('routeNavigationWarningBanner'))).findsOne();
      check(
        find.text(
          '自転車ルートには専用道がない区間が含まれる場合があります。交通ルールに従って走行してください。',
        ),
      ).findsOne();
    });

    testWidgets('API からの warnings がある場合にそれを優先表示すること', (tester) async {
      const customWarningRoute = MapRoute(
        id: 'route_card_custom_warning',
        origin: LatLng(35.681236, 139.767125),
        destination: LatLng(35.6585805, 139.7454329),
        points: [
          LatLng(35.681236, 139.767125),
          LatLng(35.6585805, 139.7454329),
        ],
        distanceMeters: 3500,
        durationSeconds: 360,
        warnings: ['道路工事のため一部区間で徐行してください'],
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
              route: customWarningRoute,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      check(find.byKey(const Key('routeNavigationWarningBanner'))).findsOne();
      check(find.text('道路工事のため一部区間で徐行してください')).findsOne();
    });

    testWidgets('車ルートで warnings がない場合は警告バナーが表示されないこと', (tester) async {
      const drivingRoute = MapRoute(
        id: 'route_card_driving_no_warning',
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
              route: drivingRoute,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      check(
        find.byKey(const Key('routeNavigationWarningBanner')),
      ).findsNothing();
    });
  });
}
