import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/map/domain/map_spot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('MapSpot & SpotCategory Unit Tests', () {
    test('MapSpot が正しくインスタンス化できること', () {
      const spot = MapSpot(
        id: 'spot_1',
        name: '東京タワー',
        category: SpotCategory.sightseeing,
        latitude: 35.6585805,
        longitude: 139.7454329,
        address: '東京都港区芝公園4-2-8',
        description: '東京のシンボルタワー',
        rating: 4.5,
      );

      check(spot.id).equals('spot_1');
      check(spot.name).equals('東京タワー');
      check(spot.category).equals(SpotCategory.sightseeing);
      check(spot.latitude).equals(35.6585805);
      check(spot.longitude).equals(139.7454329);
      check(spot.address).equals('東京都港区芝公園4-2-8');
      check(spot.description).equals('東京のシンボルタワー');
      check(spot.rating).equals(4.5);
    });

    testWidgets('SpotCategoryX 拡張が正しく各属性を返すこと', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();

      for (final category in SpotCategory.values) {
        check(category.localizedName(l10n)).isNotEmpty();
        check(category.icon).isA<IconData>();
        check(category.color).isA<Color>();
        check(category.markerHue).isA<double>();
      }

      check(SpotCategory.cafe.markerHue).equals(BitmapDescriptor.hueOrange);
      check(SpotCategory.park.markerHue).equals(BitmapDescriptor.hueGreen);
      check(SpotCategory.restaurant.markerHue).equals(BitmapDescriptor.hueRose);
      check(
        SpotCategory.sightseeing.markerHue,
      ).equals(BitmapDescriptor.hueViolet);
      check(SpotCategory.shopping.markerHue).equals(BitmapDescriptor.hueAzure);
      check(SpotCategory.other.markerHue).equals(BitmapDescriptor.hueRed);
    });
  });
}
