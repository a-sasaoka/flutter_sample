// coverage:ignore-file
import 'package:drift/drift.dart';

/// QRコードスキャン履歴テーブル
class QrScanHistories extends Table {
  /// 主キーID（自動連番）
  IntColumn get id => integer().autoIncrement()();

  /// 読み取ったQRコードの内容（文字列）
  TextColumn get rawValue => text().unique()();

  /// スキャンした日時
  DateTimeColumn get scannedAt => dateTime()();
}
