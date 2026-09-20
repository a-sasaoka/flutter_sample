import 'package:drift/drift.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/core/database/database_provider.dart';
import 'package:flutter_sample/src/features/qr_scanner/data/qr_scan_histories_table.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'qr_scan_histories_dao.g.dart';

/// QRコード履歴のデータ操作を担当するDAOクラス
@DriftAccessor(tables: [QrScanHistories])
class QrScanHistoriesDao extends DatabaseAccessor<AppDatabase>
    with _$QrScanHistoriesDaoMixin {
  /// コンストラクタ
  QrScanHistoriesDao(super.attachedDatabase);

  /// すべての履歴をスキャン日時の降順（最新順）でリアルタイム監視する
  Stream<List<QrScanHistory>> watchAllHistories() =>
      (select(qrScanHistories)..orderBy([
            (t) => OrderingTerm.desc(t.scannedAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
          .watch();

  /// すべての履歴をスキャン日時の降順（最新順）で取得する
  Future<List<QrScanHistory>> getAllHistories() =>
      (select(qrScanHistories)..orderBy([
            (t) => OrderingTerm.desc(t.scannedAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
          .get();

  /// QRコード履歴を保存する（同一の文字列が存在する場合は日時を最新に更新）
  Future<void> upsertHistory(String rawValue, {DateTime? scannedAt}) async {
    final time = scannedAt ?? DateTime.now();
    await into(qrScanHistories).insert(
      QrScanHistoriesCompanion(
        rawValue: Value(rawValue),
        scannedAt: Value(time),
      ),
      onConflict: DoUpdate(
        (old) => QrScanHistoriesCompanion(scannedAt: Value(time)),
        target: [qrScanHistories.rawValue],
      ),
    );
  }

  /// 指定したIDの履歴を1件削除する
  Future<int> deleteHistory(int id) =>
      (delete(qrScanHistories)..where((t) => t.id.equals(id))).go();

  /// すべての履歴を全件削除する
  Future<int> deleteAllHistories() => delete(qrScanHistories).go();
}

/// [QrScanHistoriesDao] を提供するプロバイダー
@riverpod
QrScanHistoriesDao qrScanHistoriesDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.qrScanHistoriesDao;
}
