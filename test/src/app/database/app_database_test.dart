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

    test('schemaVersion returns 1', () {
      expect(database.schemaVersion, 1);
    });

    test('テーブル操作の基本テスト (CRUD)', () async {
      // Create
      await database
          .into(database.memos)
          .insert(
            MemosCompanion.insert(
              id: 'test-id-1',
              title: 'テストタイトル',
              content: 'テストコンテンツ',
              createdAt: DateTime(2026, 5),
              updatedAt: DateTime(2026, 5),
            ),
          );

      // Read
      var memos = await database.select(database.memos).get();
      expect(memos.length, 1);
      expect(memos.first.id, 'test-id-1');
      expect(memos.first.title, 'テストタイトル');
      expect(memos.first.content, 'テストコンテンツ');
      expect(memos.first.createdAt, DateTime(2026, 5));
      expect(memos.first.updatedAt, DateTime(2026, 5));

      // Update
      await database
          .update(database.memos)
          .replace(
            memos.first.copyWith(title: '更新されたタイトル'),
          );
      memos = await database.select(database.memos).get();
      expect(memos.first.title, '更新されたタイトル');

      // Delete
      await database.delete(database.memos).delete(memos.first);
      memos = await database.select(database.memos).get();
      expect(memos.isEmpty, true);
    });
  });
}
