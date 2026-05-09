import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_sample/src/features/memos/data/memo_table.dart';

part 'app_database.g.dart';

/// 各機能のテーブルを一つにまとめた、アプリ全体のデータベース
@DriftDatabase(tables: [Memos])
class AppDatabase extends _$AppDatabase {
  /// コンストラクタ
  AppDatabase([QueryExecutor? e])
    : super(e ?? driftDatabase(name: 'my_app_db'));

  @override
  int get schemaVersion => 1;
}
