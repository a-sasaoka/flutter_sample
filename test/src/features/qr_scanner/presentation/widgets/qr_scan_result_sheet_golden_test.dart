import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/url_launcher_service.dart';
import 'package:flutter_sample/src/features/qr_scanner/presentation/widgets/qr_scan_result_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../golden_test_helper.dart';

class MockUrlLauncherService extends Mock implements UrlLauncherService {}

void main() {
  group('QrScanResultSheet Golden Tests', () {
    Widget buildSheetForGolden({
      required String rawValue,
      required bool isUrl,
      required ThemeMode themeMode,
    }) {
      final mockUrlService = MockUrlLauncherService();
      when(() => mockUrlService.isWebUrl(any())).thenReturn(isUrl);

      final isDark = themeMode == ThemeMode.dark;

      return ProviderScope(
        overrides: [
          urlLauncherServiceProvider.overrideWithValue(mockUrlService),
        ],
        child: buildGoldenTestApp(
          home: Scaffold(
            backgroundColor: isDark ? Colors.black54 : Colors.black26,
            body: Align(
              alignment: Alignment.bottomCenter,
              child: QrScanResultSheet(rawValue: rawValue),
            ),
          ),
          themeMode: themeMode,
        ),
      );
    }

    // ignore: discarded_futures, testing framework registers tests synchronously
    goldenTest(
      'QrScanResultSheet の描画 (URL/プレーンテキスト・ライト/ダーク)',
      fileName: 'qr_scan_result_sheet',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'URL Result - Light Mode',
            child: SizedBox(
              width: 390,
              height: 480,
              child: buildSheetForGolden(
                rawValue: 'https://flutter.dev/docs/get-started',
                isUrl: true,
                themeMode: ThemeMode.light,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'URL Result - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 480,
              child: buildSheetForGolden(
                rawValue: 'https://flutter.dev/docs/get-started',
                isUrl: true,
                themeMode: ThemeMode.dark,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Plain Text Result - Light Mode',
            child: SizedBox(
              width: 390,
              height: 480,
              child: buildSheetForGolden(
                rawValue: 'Hello Flutter! QR Code scanner sample application.',
                isUrl: false,
                themeMode: ThemeMode.light,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Plain Text Result - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 480,
              child: buildSheetForGolden(
                rawValue: 'Hello Flutter! QR Code scanner sample application.',
                isUrl: false,
                themeMode: ThemeMode.dark,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
