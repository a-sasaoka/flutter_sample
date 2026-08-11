import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/map/domain/map_spot.dart';
import 'package:flutter_sample/src/features/map/presentation/widgets/spot_detail_bottom_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpotDetailBottomSheet Widget Tests', () {
    testWidgets('スポットの詳細情報が正しく描画されること', (tester) async {
      const spot = MapSpot(
        id: 'spot_1',
        name: '東京タワー',
        category: SpotCategory.sightseeing,
        latitude: 35.6585805,
        longitude: 139.7454329,
        address: '東京都港区芝公園4-2-8',
        description: '高さ333mの総合電波塔。',
        rating: 4.6,
      );

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ja'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: SpotDetailBottomSheet(spot: spot),
          ),
        ),
      );
      await tester.pump();

      check(find.text('観光地')).findsOne();
      check(find.text('東京タワー')).findsOne();
      check(find.text('東京都港区芝公園4-2-8')).findsOne();
      check(find.text('高さ333mの総合電波塔。')).findsOne();
      check(find.text('4.6')).findsOne();
    });

    testWidgets('ルート案内ボタンをタップすると onStartRoutePressed コールバックが呼ばれること', (
      tester,
    ) async {
      var routePressed = false;
      const spot = MapSpot(
        id: 'spot_2',
        name: '代々木公園',
        category: SpotCategory.park,
        latitude: 35.671736,
        longitude: 139.694945,
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
            body: SpotDetailBottomSheet(
              spot: spot,
              onStartRoutePressed: () {
                routePressed = true;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final buttonFinder = find.byKey(const Key('spotDetailStartRouteButton'));
      check(buttonFinder).findsOne();

      await tester.tap(buttonFinder);
      await tester.pump();

      check(routePressed).isTrue();
    });
  });
}
