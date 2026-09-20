import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/url_launcher_service.dart';
import 'package:flutter_sample/src/features/qr_scanner/data/qr_scan_histories_dao.dart';
import 'package:flutter_sample/src/features/qr_scanner/presentation/qr_scanner_history_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../golden_test_helper.dart';

class MockQrScanHistoriesDao extends Mock implements QrScanHistoriesDao {}

class MockUrlLauncherService extends Mock implements UrlLauncherService {}

void main() {
  group('QrScannerHistoryScreen Golden Tests', () {
    Widget buildHistoryForGolden({
      required List<QrScanHistory> histories,
      required ThemeMode themeMode,
    }) {
      final mockDao = MockQrScanHistoriesDao();
      final mockUrlService = MockUrlLauncherService();

      when(
        // モックの仕様上、クロージャとして渡す必要があるため、unnecessary_lambdas を無視します。
        // ignore: unnecessary_lambdas
        () => mockDao.watchAllHistories(),
      ).thenAnswer((_) => Stream.value(histories));
      when(() => mockUrlService.isWebUrl(any())).thenAnswer((invocation) {
        final arg = invocation.positionalArguments.first as String;
        return arg.startsWith('http://') || arg.startsWith('https://');
      });

      return ProviderScope(
        overrides: [
          qrScanHistoriesDaoProvider.overrideWithValue(mockDao),
          urlLauncherServiceProvider.overrideWithValue(mockUrlService),
        ],
        child: buildGoldenTestApp(
          home: const QrScannerHistoryScreen(),
          themeMode: themeMode,
        ),
      );
    }

    // ignore: discarded_futures, testing framework registers tests synchronously
    goldenTest(
      'QrScannerHistoryScreen の描画 (ライト/ダーク・空/データあり)',
      fileName: 'qr_scanner_history_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Empty State - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildHistoryForGolden(
                histories: [],
                themeMode: ThemeMode.light,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Empty State - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildHistoryForGolden(
                histories: [],
                themeMode: ThemeMode.dark,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'With Histories - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildHistoryForGolden(
                histories: [
                  QrScanHistory(
                    id: 1,
                    rawValue: 'https://flutter.dev',
                    scannedAt: DateTime(2026, 9, 20, 10, 30),
                  ),
                  QrScanHistory(
                    id: 2,
                    rawValue: 'WIFI:S:MyNetwork;T:WPA;P:secret123;;',
                    scannedAt: DateTime(2026, 9, 19, 15, 45),
                  ),
                  QrScanHistory(
                    id: 3,
                    rawValue: 'https://pub.dev/packages/mobile_scanner',
                    scannedAt: DateTime(2026, 9, 18, 9, 15),
                  ),
                ],
                themeMode: ThemeMode.light,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'With Histories - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildHistoryForGolden(
                histories: [
                  QrScanHistory(
                    id: 1,
                    rawValue: 'https://flutter.dev',
                    scannedAt: DateTime(2026, 9, 20, 10, 30),
                  ),
                  QrScanHistory(
                    id: 2,
                    rawValue: 'WIFI:S:MyNetwork;T:WPA;P:secret123;;',
                    scannedAt: DateTime(2026, 9, 19, 15, 45),
                  ),
                  QrScanHistory(
                    id: 3,
                    rawValue: 'https://pub.dev/packages/mobile_scanner',
                    scannedAt: DateTime(2026, 9, 18, 9, 15),
                  ),
                ],
                themeMode: ThemeMode.dark,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
