import 'package:checks/checks.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/features/memos/data/memos_dao.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('MemosDao テスト', () {
    late AppDatabase database;
    late MemosDao dao;
    const testUserId = 'test-user-123';
    const otherUserId = 'other-user-456';

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      dao = database.memosDao;
    });

    tearDown(() async {
      await database.close();
    });

    test('【正常系】メモの挿入・ID指定取得・全件取得・更新・一括挿入が正しく動作すること', () async {
      final now = DateTime(2026, 10, 25, 10);
      final memoCompanion = MemosCompanion.insert(
        id: 'memo-1',
        userId: testUserId,
        title: 'テストタイトル',
        content: 'テスト内容',
        createdAt: now,
        updatedAt: now,
        category: const Value(MemoCategory.work),
      );

      await dao.insertMemo(memoCompanion);

      // getMemoById
      final memo = await dao.getMemoById('memo-1', testUserId);
      check(memo.id).equals('memo-1');
      check(memo.title).equals('テストタイトル');
      check(memo.category).equals(MemoCategory.work);

      // getAllMemos
      final allMemos = await dao.getAllMemos(testUserId);
      check(allMemos.length).equals(1);

      // watchAllMemos
      final streamMemos = await dao.watchAllMemos(testUserId).first;
      check(streamMemos.length).equals(1);

      // updateMemo
      await dao.updateMemo(
        'memo-1',
        testUserId,
        MemosCompanion(
          title: const Value('更新されたタイトル'),
          updatedAt: Value(now.add(const Duration(minutes: 5))),
        ),
      );
      final updated = await dao.getMemoById('memo-1', testUserId);
      check(updated.title).equals('更新されたタイトル');

      // upsertMemos
      await dao.upsertMemos([
        MemosCompanion.insert(
          id: 'memo-2',
          userId: testUserId,
          title: 'メモ2',
          content: '内容2',
          createdAt: now,
          updatedAt: now,
        ),
        MemosCompanion.insert(
          id: 'memo-1',
          userId: testUserId,
          title: '一括更新されたタイトル1',
          content: 'テスト内容',
          createdAt: now,
          updatedAt: now,
        ),
      ]);
      final afterUpsert = await dao.getAllMemos(testUserId);
      check(afterUpsert.length).equals(2);

      // getMemosByIds
      final byIds = await dao.getMemosByIds(['memo-1', 'memo-2'], testUserId);
      check(byIds.length).equals(2);
    });

    test('【正常系】未同期メモの取得および同期状態更新が正しく動作すること', () async {
      final now = DateTime(2026, 10, 25, 10);
      await dao.upsertMemos([
        MemosCompanion.insert(
          id: 'memo-synced',
          userId: testUserId,
          title: '同期済みメモ',
          content: '内容',
          createdAt: now,
          updatedAt: now,
          isSynced: const Value(true),
        ),
        MemosCompanion.insert(
          id: 'memo-unsynced',
          userId: testUserId,
          title: '未同期メモ',
          content: '内容',
          createdAt: now,
          updatedAt: now,
          isSynced: const Value(false),
        ),
      ]);

      final unsynced = await dao.getUnsyncedMemos(testUserId);
      check(unsynced.length).equals(1);
      check(unsynced.first.id).equals('memo-unsynced');

      // 同期状態の更新
      await dao.updateSyncStatus(['memo-unsynced'], testUserId, isSynced: true);
      final unsyncedAfter = await dao.getUnsyncedMemos(testUserId);
      check(unsyncedAfter).isEmpty();
    });

    group('watchFilteredMemos & getFilteredMemos 絞り込みテスト', () {
      setUp(() async {
        final now = DateTime(2026, 10, 25, 10);
        await dao.upsertMemos([
          MemosCompanion.insert(
            id: 'work-1',
            userId: testUserId,
            title: 'Flutter案件のタスク',
            content: '設計ドキュメントの作成',
            createdAt: now,
            updatedAt: now,
            category: const Value(MemoCategory.work),
            isSynced: const Value(true),
          ),
          MemosCompanion.insert(
            id: 'personal-1',
            userId: testUserId,
            title: 'スーパーで買い物',
            content: '牛乳と卵を買う',
            createdAt: now,
            updatedAt: now,
            category: const Value(MemoCategory.personal),
            isSynced: const Value(false),
          ),
          MemosCompanion.insert(
            id: 'idea-1',
            userId: testUserId,
            title: '新しいアプリのアイデア',
            content: 'Flutter × AIの組み合わせ',
            createdAt: now,
            updatedAt: now,
            category: const Value(MemoCategory.idea),
            isSynced: const Value(false),
          ),
          MemosCompanion.insert(
            id: 'deleted-1',
            userId: testUserId,
            title: '削除されたメモ',
            content: 'Flutter',
            createdAt: now,
            updatedAt: now,
            isDeleted: const Value(true),
          ),
          MemosCompanion.insert(
            id: 'other-user-memo',
            userId: otherUserId,
            title: '他人のFlutterメモ',
            content: '他人',
            createdAt: now,
            updatedAt: now,
          ),
        ]);
      });

      test('【正常系】キーワード検索（タイトルまたは本文に部分一致、大文字小文字無視）', () async {
        // 'flutter' で検索（タイトルと本文の両方でヒット）
        final results = await dao.getFilteredMemos(
          testUserId,
          query: 'flutter',
        );
        // work-1(タイトル) と idea-1(本文) がヒット。deleted-1 と他人のメモは除外
        check(results.length).equals(2);
        check(
          results.map((m) => m.id).toList(),
        ).deepEquals(['work-1', 'idea-1']);
      });

      test('【正常系】カテゴリ（MemoCategory）指定による絞り込み', () async {
        final results = await dao.getFilteredMemos(
          testUserId,
          category: MemoCategory.personal,
        );
        check(results.length).equals(1);
        check(results.first.id).equals('personal-1');
      });

      test('【正常系】未同期のみ（unsyncedOnly: true）の絞り込み', () async {
        final results = await dao.getFilteredMemos(
          testUserId,
          unsyncedOnly: true,
        );
        check(results.length).equals(2);
        check(
          results.map((m) => m.id).toList(),
        ).deepEquals(['personal-1', 'idea-1']);
      });

      test('【正常系】キーワード + カテゴリ + 未同期の複合条件絞り込み', () async {
        final results = await dao.getFilteredMemos(
          testUserId,
          query: 'AI',
          category: MemoCategory.idea,
          unsyncedOnly: true,
        );
        check(results.length).equals(1);
        check(results.first.id).equals('idea-1');
      });

      test('【正常系】watchFilteredMemos によるストリーム監視で絞り込み結果を取得できること', () async {
        final streamResult = await dao
            .watchFilteredMemos(
              testUserId,
              query: '買い物',
              category: MemoCategory.personal,
            )
            .first;
        check(streamResult.length).equals(1);
        check(streamResult.first.id).equals('personal-1');
      });

      test('【正常系】条件がすべて空の場合は有効な全件が取得されること', () async {
        final results = await dao.getFilteredMemos(testUserId);
        check(results.length).equals(3);
      });
    });
  });
}
