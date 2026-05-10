import 'package:drift/drift.dart';
import 'package:flutter_sample/src/features/memos/data/memo_table.dart';
import 'package:flutter_sample/src/features/memos/data/memos_dao.dart';

part 'app_database.g.dart';

/// 各機能のテーブルを一つにまとめた、アプリ全体のデータベース
@DriftDatabase(tables: [Memos], daos: [MemosDao])
class AppDatabase extends _$AppDatabase {
  /// コンストラクタ
  ///
  /// データベースの接続（[QueryExecutor]）を外部から注入します。
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      // 初回起動時にすべてのテーブルを作成する
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // 今後、テーブルの定義を変更した際（バージョンアップ時）の処理をここに記述する
    },
    beforeOpen: (details) async {
      // SQLiteの外部キー制約を有効にする場合などはここで設定
    },
  );
}
