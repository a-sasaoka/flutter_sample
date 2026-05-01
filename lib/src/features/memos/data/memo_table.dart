// coverage:ignore-file
import 'package:drift/drift.dart';

/// メモのテーブル
class Memos extends Table {
  /// メモの番号（自動で1, 2, 3...と増える）
  IntColumn get id => integer().autoIncrement()();

  /// メモのタイトル
  TextColumn get title => text()();

  /// メモの中身
  TextColumn get content => text()();

  /// 作成した日時
  DateTimeColumn get createdAt => dateTime()();
}
