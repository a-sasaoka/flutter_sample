import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/map/presentation/widgets/transit_guide_bottom_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget({
    required VoidCallback onOpenGoogleMapsPressed,
    String? destinationName,
    VoidCallback? onCancelPressed,
  }) {
    return MaterialApp(
      locale: const Locale('ja'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: TransitGuideBottomSheet(
          destinationName: destinationName,
          onOpenGoogleMapsPressed: onOpenGoogleMapsPressed,
          onCancelPressed: onCancelPressed,
        ),
      ),
    );
  }

  group('TransitGuideBottomSheet Tests', () {
    testWidgets('目的地名称がある場合、名称と各種案内・ボタンが正しく描画されること', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          destinationName: '東京タワー',
          onOpenGoogleMapsPressed: () {},
        ),
      );
      await tester.pumpAndSettle();

      check(find.text('公共交通機関のルート案内')).findsOne();
      check(find.text('東京タワー')).findsOne();
      check(find.byIcon(Icons.place_outlined)).findsOne();
      check(find.textContaining('Google Maps APIの仕様により')).findsOne();
      check(find.text('公式Googleマップで最新の乗換案内（運行情報・時刻表・運賃）を開きますか？')).findsOne();
      check(
        find.byKey(const Key('transitGuideOpenGoogleMapsButton')),
      ).findsOne();
      check(find.byKey(const Key('transitGuideCancelButton'))).findsOne();
    });

    testWidgets('目的地名称が null または空白の場合、目的地行が表示されないこと', (tester) async {
      await tester.pumpWidget(buildTestWidget(onOpenGoogleMapsPressed: () {}));
      await tester.pumpAndSettle();

      check(find.text('公共交通機関のルート案内')).findsOne();
      check(find.byIcon(Icons.place_outlined)).findsNothing();

      await tester.pumpWidget(
        buildTestWidget(destinationName: '   ', onOpenGoogleMapsPressed: () {}),
      );
      await tester.pumpAndSettle();

      check(find.byIcon(Icons.place_outlined)).findsNothing();
    });

    testWidgets('「Googleマップで開く」ボタンタップで onOpenGoogleMapsPressed が呼ばれること', (
      tester,
    ) async {
      var openPressed = false;
      await tester.pumpWidget(
        buildTestWidget(
          onOpenGoogleMapsPressed: () {
            openPressed = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('transitGuideOpenGoogleMapsButton')),
      );
      await tester.pump();

      check(openPressed).isTrue();
    });

    testWidgets('「キャンセル」ボタンタップで onCancelPressed が呼ばれること', (tester) async {
      var cancelPressed = false;
      await tester.pumpWidget(
        buildTestWidget(
          onOpenGoogleMapsPressed: () {},
          onCancelPressed: () {
            cancelPressed = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('transitGuideCancelButton')));
      await tester.pump();

      check(cancelPressed).isTrue();
    });

    testWidgets(
      'onCancelPressed が null の場合、キャンセルボタン押下で Navigator.pop が行われること',
      (tester) async {
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
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      unawaited(
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (_) => TransitGuideBottomSheet(
                            onOpenGoogleMapsPressed: () {},
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // モーダルを開く
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        check(find.byType(TransitGuideBottomSheet)).findsOne();

        // キャンセルボタンを押す
        await tester.tap(find.byKey(const Key('transitGuideCancelButton')));
        await tester.pumpAndSettle();

        check(find.byType(TransitGuideBottomSheet)).findsNothing();
      },
    );
  });
}
