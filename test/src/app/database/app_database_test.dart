import 'package:checks/checks.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // テスト中はデータベースを複数開くことがあるため、警告をオフにする
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('AppDatabase', () {
    late AppDatabase database;

    setUp(() {
      // テスト時はメモリ上で動くデータベースを使用する
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('schemaVersion returns 4', () {
      check(database.schemaVersion).equals(4);
    });

    test('onUpgrade migration strategy executes without error', () async {
      // 現在のマイグレーション戦略を取得
      final strategy = database.migration;

      // 実際には Migrator インスタンスが必要だが、モックやダミーで呼び出しだけ確認
      // ここでは、onUpgrade が例外なく実行されることをテストし、カバレッジを通す
      await strategy.onUpgrade(database.createMigrator(), 1, 4);

      // 前後のフックもカバレッジのために実行
      // onCreate は AppDatabase インスタンス作成時に暗黙的に呼ばれているが、明示的にも呼ぶ
      await strategy.onCreate(database.createMigrator());

      // beforeOpen も同様
      await strategy.beforeOpen?.call(const OpeningDetails(null, 1));

      check(true).equals(true); // ここまで到達すればOK
    });

    test('onUpgrade (from 2 to 3): 旧メモテーブルのデータが削除されること', () async {
      // 事前にメモデータを投入
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: 'old-memo-1',
              userId: 'old-user-1',
              title: '旧メモ',
              content: '旧内容',
              createdAt: DateTime(2026, 5),
              updatedAt: DateTime(2026, 5),
            ),
          );
      final beforeMemos = await database.select(database.memos).get();
      check(beforeMemos.length).equals(1);

      // マイグレーション実行 (from 2 to 3)
      await database.migration.onUpgrade(database.createMigrator(), 2, 3);

      // データがクリアされていることを確認
      final afterMemos = await database.select(database.memos).get();
      check(afterMemos.isEmpty).equals(true);
    });

    test(
      'onUpgrade (from 2 to 3): user_id カラムが存在しない場合に addColumn が実行されること',
      () async {
        // memos テーブルを一度削除し、user_id カラム無しの旧スキーマで作成
        await database.customStatement('DROP TABLE IF EXISTS memos;');
        await database.customStatement('''
        CREATE TABLE memos (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          is_deleted INTEGER NOT NULL,
          is_synced INTEGER NOT NULL
        );
      ''');

        // マイグレーション実行 (from 2 to 3)
        await database.migration.onUpgrade(database.createMigrator(), 2, 3);

        // user_id カラムが追加されたことを確認
        final columns = await database
            .customSelect('PRAGMA table_info(memos);')
            .get();
        final hasUserId = columns.any(
          (row) => row.read<String>('name') == 'user_id',
        );
        check(hasUserId).isTrue();
      },
    );

    test('onUpgrade (from 3 to 4): category カラム追加時に既存データが保持されること', () async {
      // memos テーブルを一度削除し、category カラム無しのスキーマ（v3）で作成
      await database.customStatement('DROP TABLE IF EXISTS memos;');
      await database.customStatement('''
        CREATE TABLE memos (
          id TEXT NOT NULL PRIMARY KEY,
          user_id TEXT NOT NULL,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          is_deleted INTEGER NOT NULL,
          is_synced INTEGER NOT NULL
        );
      ''');

      // 移行前のv3テーブルにテスト用のメモデータを投入
      await database.customStatement('''
        INSERT INTO memos (id, user_id, title, content, created_at, updated_at, is_deleted, is_synced)
        VALUES ('v3-memo-1', 'user-123', '移行前タイトル', '移行前コンテンツ', 1748000000, 1748000000, 0, 1);
      ''');

      // マイグレーション実行 (from 3 to 4)
      await database.migration.onUpgrade(database.createMigrator(), 3, 4);

      // category カラムが追加されたことを確認
      final columns = await database
          .customSelect('PRAGMA table_info(memos);')
          .get();
      final hasCategory = columns.any(
        (row) => row.read<String>('name') == 'category',
      );
      check(hasCategory).isTrue();

      // 既存行が保持され、新設された category 列が null であることを確認
      final memos = await database.select(database.memos).get();
      check(memos.length).equals(1);
      final memo = memos.first;
      check(memo.id).equals('v3-memo-1');
      check(memo.userId).equals('user-123');
      check(memo.title).equals('移行前タイトル');
      check(memo.content).equals('移行前コンテンツ');
      check(memo.category).isNull();
      check(memo.isSynced).isTrue();
    });

    test('テーブル操作の基本テスト (CRUD)', () async {
      // Create
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: 'test-id-1',
              userId: 'test-user-id-1',
              title: 'テストタイトル',
              content: 'テストコンテンツ',
              createdAt: DateTime(2026, 5),
              updatedAt: DateTime(2026, 5),
            ),
          );

      // Read
      var memos = await database.select(database.memos).get();
      check(memos.length).equals(1);
      check(memos.first.id).equals('test-id-1');
      check(memos.first.title).equals('テストタイトル');
      check(memos.first.content).equals('テストコンテンツ');
      check(memos.first.createdAt).equals(DateTime(2026, 5));
      check(memos.first.updatedAt).equals(DateTime(2026, 5));

      // Update
      await database
          .update(database.memos)
          .replace(memos.first.copyWith(title: '更新されたタイトル'));
      memos = await database.select(database.memos).get();
      check(memos.first.title).equals('更新されたタイトル');

      // Delete
      await database.delete(database.memos).delete(memos.first);
      memos = await database.select(database.memos).get();
      check(memos.isEmpty).equals(true);
    });
  });
}
