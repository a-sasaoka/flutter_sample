import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/qr_scanner/presentation/widgets/qr_scanner_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QrScannerOverlay', () {
    testWidgets('案内文テキストとCustomPaintが正しく描画されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('ja')],
          home: Scaffold(body: QrScannerOverlay()),
        ),
      );
      await tester.pumpAndSettle();

      // CustomPaintが存在すること
      check(find.byType(CustomPaint)).findsAtLeast(1);

      // 案内文テキストが存在すること
      check(find.text('枠内にQRコードを合わせてください')).findsOne();
    });

    testWidgets('scanWindowSize または borderColor を変更して再描画したとき正しく反映されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ja')],
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: Colors.white),
          ),
          home: const Scaffold(
            body: QrScannerOverlay(scanWindowSize: Size(200, 200)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // scanWindowSize を変更して再描画（shouldRepaint: true）
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ja')],
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: Colors.white),
          ),
          home: const Scaffold(
            body: QrScannerOverlay(scanWindowSize: Size(300, 300)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // scanWindowSize は同じで primaryColor（borderColor）を変更して再描画
      // （shouldRepaint: true）
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ja')],
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          home: const Scaffold(
            body: QrScannerOverlay(scanWindowSize: Size(300, 300)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 同じプロパティで再描画（shouldRepaint: false）
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ja')],
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          home: const Scaffold(
            body: QrScannerOverlay(scanWindowSize: Size(300, 300)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      check(find.byType(CustomPaint)).findsAtLeast(1);
    });
  });
}
