import 'package:checks/checks.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/core/database/database_provider.dart';
import 'package:flutter_sample/src/features/qr_scanner/data/qr_scan_histories_dao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('QrScanHistoriesDao', () {
    late AppDatabase database;
    late QrScanHistoriesDao dao;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      dao = database.qrScanHistoriesDao;
    });

    tearDown(() async {
      await database.close();
    });

    test('新規のQRコードを保存できること', () async {
      await dao.upsertHistory('https://example.com');

      final histories = await dao.getAllHistories();
      check(histories.length).equals(1);
      check(histories.first.rawValue).equals('https://example.com');
    });

    test('同じQRコードを保存した場合、レコード数は増えずに日時が更新されること', () async {
      final baseTime = DateTime(2026, 9, 20, 12);
      await dao.upsertHistory('https://example.com', scannedAt: baseTime);
      final firstHistories = await dao.getAllHistories();
      final firstDate = firstHistories.first.scannedAt;

      // 1分後の日時で同じ文字列を保存
      final updatedTime = baseTime.add(const Duration(minutes: 1));
      await dao.upsertHistory('https://example.com', scannedAt: updatedTime);

      final updatedHistories = await dao.getAllHistories();
      check(updatedHistories.length).equals(1);
      check(updatedHistories.first.rawValue).equals('https://example.com');
      check(updatedHistories.first.scannedAt.isAfter(firstDate)).equals(true);
    });

    test('watchAllHistories で最新順にストリーム監視できること', () async {
      final baseTime = DateTime(2026, 9, 20, 12);
      await dao.upsertHistory('data1', scannedAt: baseTime);
      await dao.upsertHistory(
        'data2',
        scannedAt: baseTime.add(const Duration(seconds: 10)),
      );

      final streamData = await dao.watchAllHistories().first;
      check(streamData.length).equals(2);
      check(streamData[0].rawValue).equals('data2');
      check(streamData[1].rawValue).equals('data1');
    });

    test('deleteHistory で指定IDの履歴を1件削除できること', () async {
      await dao.upsertHistory('data1');
      await dao.upsertHistory('data2');
      var histories = await dao.getAllHistories();
      final targetId = histories.firstWhere((h) => h.rawValue == 'data1').id;

      final count = await dao.deleteHistory(targetId);
      check(count).equals(1);

      histories = await dao.getAllHistories();
      check(histories.length).equals(1);
      check(histories.first.rawValue).equals('data2');
    });

    test('deleteAllHistories で全件削除できること', () async {
      await dao.upsertHistory('data1');
      await dao.upsertHistory('data2');

      final count = await dao.deleteAllHistories();
      check(count).equals(2);

      final histories = await dao.getAllHistories();
      check(histories.isEmpty).equals(true);
    });

    test('qrScanHistoriesDaoProvider から正常にインスタンスを取得できること', () {
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      final providerDao = container.read(qrScanHistoriesDaoProvider);
      check(providerDao).isNotNull();
    });
  });
}
