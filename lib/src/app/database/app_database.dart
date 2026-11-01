import 'package:drift/drift.dart';
import 'package:flutter_sample/src/features/memos/data/memo_table.dart';
import 'package:flutter_sample/src/features/memos/data/memos_dao.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';
import 'package:flutter_sample/src/features/qr_scanner/data/qr_scan_histories_dao.dart';
import 'package:flutter_sample/src/features/qr_scanner/data/qr_scan_histories_table.dart';

part 'app_database.g.dart';

/// 各機能のテーブルを一つにまとめた、アプリ全体のデータベース
@DriftDatabase(
  tables: [Memos, QrScanHistories],
  daos: [MemosDao, QrScanHistoriesDao],
)
class AppDatabase extends _$AppDatabase {
  /// コンストラクタ
  ///
  /// データベースの接続（[QueryExecutor]）を外部から注入します。
  AppDatabase(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      // 初回起動時にすべてのテーブルを作成する
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // 今後、テーブルの定義を変更した際（バージョンアップ時）の処理をここに記述する
      if (from < 2) {
        await m.createTable(qrScanHistories);
      }
      if (from < 3) {
        // メモ機能のマルチユーザー対応:
        // 旧メモテーブルのデータをクリア（初期化）し、userId カラムを追加
        await delete(memos).go();

        // 冪等性確保: user_id カラムが存在しない場合のみ追加
        final columns = await customSelect('PRAGMA table_info(memos);').get();
        final hasUserId = columns.any(
          (row) => row.read<String>('name') == 'user_id',
        );
        if (!hasUserId) {
          await m.addColumn(memos, memos.userId);
        }
      }
      if (from < 4) {
        // メモ機能のタグ・カテゴリ対応:
        // 冪等性確保: category カラムが存在しない場合のみ追加
        final columns = await customSelect('PRAGMA table_info(memos);').get();
        final hasCategory = columns.any(
          (row) => row.read<String>('name') == 'category',
        );
        if (!hasCategory) {
          await m.addColumn(memos, memos.category);
        }
      }
      if (from < 5) {
        // メモ機能の並び替え（ドラッグ＆ドロップ）対応:
        // 冪等性確保: sort_order カラムが存在しない場合のみ追加
        final columns = await customSelect('PRAGMA table_info(memos);').get();
        final hasSortOrder = columns.any(
          (row) => row.read<String>('name') == 'sort_order',
        );
        if (!hasSortOrder) {
          await m.addColumn(memos, memos.sortOrder);
        }

        // 既存メモが存在する場合、ユーザーごとに作成日時の降順で連番（0, 1, 2...）を初期設定
        final existingMemos = await (select(
          memos,
        )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
        final userSortCount = <String, int>{};
        for (final memo in existingMemos) {
          final count = userSortCount[memo.userId] ?? 0;
          await (update(memos)..where((t) => t.id.equals(memo.id))).write(
            MemosCompanion(sortOrder: Value(count)),
          );
          userSortCount[memo.userId] = count + 1;
        }
      }
    },
    beforeOpen: (details) async {
      // SQLiteの外部キー制約を有効にする場合などはここで設定
    },
  );
}
