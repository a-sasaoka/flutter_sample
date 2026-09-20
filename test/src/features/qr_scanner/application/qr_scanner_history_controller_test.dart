import 'package:checks/checks.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/qr_scanner_history_controller.dart';
import 'package:flutter_sample/src/features/qr_scanner/data/qr_scan_histories_dao.dart';
import 'package:flutter_sample/src/features/qr_scanner/domain/qr_scan_history_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockQrScanHistoriesDao extends Mock implements QrScanHistoriesDao {}

void main() {
  group('QrScannerHistoryController', () {
    late MockQrScanHistoriesDao mockDao;
    late ProviderContainer container;

    setUp(() {
      mockDao = MockQrScanHistoriesDao();
      container = ProviderContainer(
        overrides: [qrScanHistoriesDaoProvider.overrideWithValue(mockDao)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'build() は DAO の watchAllHistories を QrScanHistoryModel に変換して流すこと',
      () async {
        final now = DateTime(2026, 9, 20, 12);
        final rawHistories = [
          QrScanHistory(id: 1, rawValue: 'https://example.com', scannedAt: now),
        ];

        when(
          () => mockDao.watchAllHistories(),
        ).thenAnswer((_) => Stream.value(rawHistories));

        final subscription = container.listen(
          qrScannerHistoryControllerProvider,
          (_, _) {},
        );

        final list = await container.read(
          qrScannerHistoryControllerProvider.future,
        );
        check(list.length).equals(1);
        check(list.first).equals(
          QrScanHistoryModel(
            id: 1,
            rawValue: 'https://example.com',
            scannedAt: now,
          ),
        );
        subscription.close();
      },
    );

    test('deleteHistory で DAO の deleteHistory が呼ばれること', () async {
      when(() => mockDao.deleteHistory(1)).thenAnswer((_) async => 1);
      when(
        () => mockDao.watchAllHistories(),
      ).thenAnswer((_) => Stream.value([]));

      final notifier = container.read(
        qrScannerHistoryControllerProvider.notifier,
      );
      await notifier.deleteHistory(1);

      verify(() => mockDao.deleteHistory(1)).called(1);
    });

    test('deleteAllHistories で DAO の deleteAllHistories が呼ばれること', () async {
      when(() => mockDao.deleteAllHistories()).thenAnswer((_) async => 5);
      when(
        () => mockDao.watchAllHistories(),
      ).thenAnswer((_) => Stream.value([]));

      final notifier = container.read(
        qrScannerHistoryControllerProvider.notifier,
      );
      await notifier.deleteAllHistories();

      verify(() => mockDao.deleteAllHistories()).called(1);
    });
  });
}
