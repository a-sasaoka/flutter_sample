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
              unsyncedOnly: true,
            )
            .first;
        check(streamResult.length).equals(1);
        check(streamResult.first.id).equals('personal-1');
      });

      test(
        '【正常系】watchFilteredMemos で未同期メモのみ（unsyncedOnly: true）をストリーム監視できること',
        () async {
          final streamResult = await dao
              .watchFilteredMemos(testUserId, unsyncedOnly: true)
              .first;
          check(streamResult.length).equals(2);
          final ids = streamResult.map((m) => m.id).toList();
          check(ids).contains('personal-1');
          check(ids).contains('idea-1');
        },
      );

      test('【正常系】条件がすべて空の場合は有効な全件が取得されること', () async {
        final results = await dao.getFilteredMemos(testUserId);
        check(results.length).equals(3);
      });

      test(r'【正常系】%、_、\ を含むキーワードがワイルドカードやエスケープ文字ではなくリテラルとして検索されること', () async {
        final now = DateTime(2026, 10, 25, 10);
        await dao.insertMemo(
          MemosCompanion.insert(
            id: 'wildcard-percent',
            userId: testUserId,
            title: '割引率100%セール',
            content: '詳細情報',
            createdAt: now,
            updatedAt: now,
          ),
        );
        // % がワイルドカードとして解釈された場合に誤ヒットするダミーメモ
        await dao.insertMemo(
          MemosCompanion.insert(
            id: 'wildcard-percent-dummy',
            userId: testUserId,
            title: '割引率100円セール',
            content: '詳細情報',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await dao.insertMemo(
          MemosCompanion.insert(
            id: 'wildcard-underscore',
            userId: testUserId,
            title: 'user_1の設定',
            content: '設定内容',
            createdAt: now,
            updatedAt: now,
          ),
        );
        // _ がワイルドカードとして解釈された場合に誤ヒットするダミーメモ
        await dao.insertMemo(
          MemosCompanion.insert(
            id: 'wildcard-underscore-dummy',
            userId: testUserId,
            title: 'userA1の設定',
            content: '設定内容',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await dao.insertMemo(
          MemosCompanion.insert(
            id: 'wildcard-backslash',
            userId: testUserId,
            title: r'C:\path のメモ',
            content: '詳細情報',
            createdAt: now,
            updatedAt: now,
          ),
        );
        // \ がエスケープ文字として消費された場合に誤ヒットするダミーメモ
        await dao.insertMemo(
          MemosCompanion.insert(
            id: 'wildcard-backslash-dummy',
            userId: testUserId,
            title: 'C:path のメモ',
            content: '詳細情報',
            createdAt: now,
            updatedAt: now,
          ),
        );

        // '100%' で検索して「割引率100%セール」のみヒットし、「割引率100円セール」は除外されること
        final percentResults = await dao.getFilteredMemos(
          testUserId,
          query: '100%',
        );
        check(percentResults.length).equals(1);
        check(percentResults.first.id).equals('wildcard-percent');

        // 'user_1' で検索して「user_1の設定」のみヒットし、「userA1の設定」は除外されること
        final underscoreResults = await dao.getFilteredMemos(
          testUserId,
          query: 'user_1',
        );
        check(underscoreResults.length).equals(1);
        check(underscoreResults.first.id).equals('wildcard-underscore');

        // r'C:\path' で検索して「C:\path のメモ」のみヒットし、「C:path のメモ」は除外されること
        final backslashResults = await dao.getFilteredMemos(
          testUserId,
          query: r'C:\path',
        );
        check(backslashResults.length).equals(1);
        check(backslashResults.first.id).equals('wildcard-backslash');
      });

      test('【正常系】LIKEパターンが50,000バイトちょうどの境界値キーワードの場合、正常に検索できること', () async {
        final now = DateTime(2026, 10, 25, 10);
        // 両端の「%」（2バイト）と合わせてちょうど50,000バイトとなる49,998文字のキーワード
        final boundaryQuery = 'a' * 49998;
        await dao.insertMemo(
          MemosCompanion.insert(
            id: 'boundary-memo',
            userId: testUserId,
            title: '境界値テストメモ',
            content: boundaryQuery,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final results = await dao.getFilteredMemos(
          testUserId,
          query: boundaryQuery,
        );
        check(results.length).equals(1);
        check(results.first.id).equals('boundary-memo');

        final streamResults = await dao
            .watchFilteredMemos(testUserId, query: boundaryQuery)
            .first;
        check(streamResults.length).equals(1);
        check(streamResults.first.id).equals('boundary-memo');
      });

      test('【正常系】50,000バイトを超える長大キーワードの場合、SQLiteエラーにならず0件を返すこと', () async {
        // 50,001バイト以上の長いキーワード（日本語1文字は3バイト）
        final longQuery = 'あ' * 17000;
        final results = await dao.getFilteredMemos(
          testUserId,
          query: longQuery,
        );
        check(results).isEmpty();

        final streamResults = await dao
            .watchFilteredMemos(testUserId, query: longQuery)
            .first;
        check(streamResults).isEmpty();
      });
    });

    group('並び替え・復元機能のDAOテスト', () {
      test(
        '【正常系】shiftSortOrdersで指定ユーザーの全メモ（削除済み・復元対象含む）のsortOrderがシフトされること',
        () async {
          final now = DateTime(2026, 10, 25, 10);
          await dao.upsertMemos([
            MemosCompanion.insert(
              id: 'm1',
              userId: testUserId,
              title: 'M1',
              content: 'C1',
              createdAt: now,
              updatedAt: now,
              sortOrder: const Value(0),
            ),
            MemosCompanion.insert(
              id: 'm2',
              userId: testUserId,
              title: 'M2',
              content: 'C2',
              createdAt: now,
              updatedAt: now,
              sortOrder: const Value(1),
            ),
            MemosCompanion.insert(
              id: 'm-deleted',
              userId: testUserId,
              title: '削除済',
              content: 'C',
              createdAt: now,
              updatedAt: now,
              isDeleted: const Value(true),
              sortOrder: const Value(5),
            ),
            MemosCompanion.insert(
              id: 'm-other',
              userId: otherUserId,
              title: '他ユーザー',
              content: 'C',
              createdAt: now,
              updatedAt: now,
              sortOrder: const Value(0),
            ),
          ]);

          await dao.shiftSortOrders(testUserId);

          final m1 = await dao.getMemoById('m1', testUserId);
          final m2 = await dao.getMemoById('m2', testUserId);
          final mDeleted = await dao.getMemoById('m-deleted', testUserId);
          final mOther = await dao.getMemoById('m-other', otherUserId);

          check(m1.sortOrder).equals(1);
          check(m2.sortOrder).equals(2);
          check(mDeleted.sortOrder).equals(6); // 削除済み・Undo復元対象メモもシフトされる
          check(mOther.sortOrder).equals(0); // 他ユーザーはシフトされない
        },
      );

      test('【正常系】updateSortOrdersで複数のメモのsortOrderが一括更新されること', () async {
        final now = DateTime(2026, 10, 25, 10);
        await dao.upsertMemos([
          MemosCompanion.insert(
            id: 'm1',
            userId: testUserId,
            title: 'M1',
            content: 'C1',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(0),
          ),
          MemosCompanion.insert(
            id: 'm2',
            userId: testUserId,
            title: 'M2',
            content: 'C2',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(1),
          ),
        ]);

        await dao.updateSortOrders(['m2', 'm1'], testUserId);

        final m1 = await dao.getMemoById('m1', testUserId);
        final m2 = await dao.getMemoById('m2', testUserId);
        check(m1.sortOrder).equals(1);
        check(m2.sortOrder).equals(0);
      });

      test(
        '【正常系】insertMemoWithShiftで既存メモがシフトされ先頭（sortOrder: 0）に挿入されること',
        () async {
          final now = DateTime(2026, 10, 25, 10);
          await dao.insertMemo(
            MemosCompanion.insert(
              id: 'm1',
              userId: testUserId,
              title: 'M1',
              content: 'C1',
              createdAt: now,
              updatedAt: now,
              sortOrder: const Value(0),
            ),
          );

          await dao.insertMemoWithShift(
            testUserId,
            MemosCompanion.insert(
              id: 'm2',
              userId: testUserId,
              title: 'M2',
              content: 'C2',
              createdAt: now,
              updatedAt: now,
              // DAOが必ず先頭（0）に上書きすることを検証するため、あえて非ゼロ値を指定
              sortOrder: const Value(99),
            ),
          );

          final m1 = await dao.getMemoById('m1', testUserId);
          final m2 = await dao.getMemoById('m2', testUserId);
          check(m1.sortOrder).equals(1);
          check(m2.sortOrder).equals(0);
        },
      );

      test('【正常系】削除後に新規追加しUndoしてもsortOrderが重複せず順序が保たれること', () async {
        final now = DateTime(2026, 10, 25, 10);
        // 初期状態: m1(0), m2(1)
        await dao.insertMemo(
          MemosCompanion.insert(
            id: 'm1',
            userId: testUserId,
            title: 'M1',
            content: 'C1',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(0),
          ),
        );
        await dao.insertMemo(
          MemosCompanion.insert(
            id: 'm2',
            userId: testUserId,
            title: 'M2',
            content: 'C2',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(1),
          ),
        );

        // 1. m1 を論理削除（スワイプ削除相当）
        await dao.updateMemo(
          'm1',
          testUserId,
          const MemosCompanion(isDeleted: Value(true)),
        );

        // 2. 新規メモ m3 を追加（全メモがシフトされ、m3が0で挿入される）
        await dao.insertMemoWithShift(
          testUserId,
          MemosCompanion.insert(
            id: 'm3',
            userId: testUserId,
            title: 'M3',
            content: 'C3',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(0),
          ),
        );

        // 3. m1 を復元（Undo相当）
        await dao.restoreMemo(
          'm1',
          testUserId,
          now.add(const Duration(minutes: 1)),
        );

        final allMemos = await dao.getAllMemos(testUserId);
        check(allMemos.length).equals(3);

        final m3 = allMemos.firstWhere((m) => m.id == 'm3');
        final m1 = allMemos.firstWhere((m) => m.id == 'm1');
        final m2 = allMemos.firstWhere((m) => m.id == 'm2');

        // m3が先頭(0)、復元されたm1が(1)、m2が(2)となり、重複が一切ないこと
        check(m3.sortOrder).equals(0);
        check(m1.sortOrder).equals(1);
        check(m2.sortOrder).equals(2);

        // 重複がないことをSetでも検証
        final sortOrders = allMemos.map((m) => m.sortOrder).toSet();
        check(sortOrders.length).equals(3);
      });

      test('【正常系】restoreMemoで論理削除フラグが解除され未同期状態になること', () async {
        final now = DateTime(2026, 10, 25, 10);
        await dao.insertMemo(
          MemosCompanion.insert(
            id: 'm-restore',
            userId: testUserId,
            title: '復元対象',
            content: '内容',
            createdAt: now,
            updatedAt: now,
            isDeleted: const Value(true),
            isSynced: const Value(true),
          ),
        );

        final restoreTime = now.add(const Duration(minutes: 10));
        await dao.restoreMemo('m-restore', testUserId, restoreTime);

        final restored = await dao.getMemoById('m-restore', testUserId);
        check(restored.isDeleted).isFalse();
        check(restored.isSynced).isFalse();
        check(restored.updatedAt).equals(restoreTime);
      });

      test('【正常系】mergeRemoteMemosで既存メモの順序を維持しつつ新規メモを先頭にマージすること', () async {
        final now = DateTime(2026, 10, 25, 10);
        await dao.insertMemo(
          MemosCompanion.insert(
            id: 'm1',
            userId: testUserId,
            title: 'M1',
            content: 'C1',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(0),
          ),
        );

        await dao.mergeRemoteMemos(testUserId, [
          {
            'id': 'm1',
            'title': 'M1更新',
            'content': 'C1更新',
            'createdAt': now,
            'updatedAt': now.add(const Duration(minutes: 5)),
            'isDeleted': false,
          },
          {
            'id': 'm2',
            'title': 'M2新規',
            'content': 'C2新規',
            'createdAt': now,
            'updatedAt': now,
            'isDeleted': false,
          },
        ]);

        final m1 = await dao.getMemoById('m1', testUserId);
        final m2 = await dao.getMemoById('m2', testUserId);
        check(m1.title).equals('M1更新');
        check(m1.sortOrder).equals(1);
        check(m2.title).equals('M2新規');
        check(m2.sortOrder).equals(0);
      });

      test('【正常系】既存メモの更新を含むmergeRemoteMemosとupdateSortOrdersを並行実行しても'
          '最新の並び順と更新内容が正しく反映されること', () async {
        final now = DateTime(2026, 10, 25, 10);
        await dao.insertMemo(
          MemosCompanion.insert(
            id: 'm1',
            userId: testUserId,
            title: 'M1',
            content: 'C1',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(0),
          ),
        );
        await dao.insertMemo(
          MemosCompanion.insert(
            id: 'm2',
            userId: testUserId,
            title: 'M2',
            content: 'C2',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(1),
          ),
        );

        // 既存メモm1の更新（リモートマージ）と、ローカルでの並び替えを同時に実行
        await Future.wait([
          dao.mergeRemoteMemos(testUserId, [
            {
              'id': 'm1',
              'title': 'M1リモート更新',
              'content': 'C1リモート更新',
              'createdAt': now,
              'updatedAt': now.add(const Duration(minutes: 5)),
              'isDeleted': false,
            },
          ]),
          dao.updateSortOrders(['m2', 'm1'], testUserId),
        ]);

        final m1 = await dao.getMemoById('m1', testUserId);
        final m2 = await dao.getMemoById('m2', testUserId);

        // m1のリモート更新内容（タイトル）が正しく反映されていること
        check(m1.title).equals('M1リモート更新');
        // 並び替えの結果（m2が0、m1が1）が保持されていること
        check(m2.sortOrder).equals(0);
        check(m1.sortOrder).equals(1);
      });

      test(
        '【正常系】削除後に残りのメモを並び替えてからUndoした際、元の位置（sortOrder）で復元され重複しないこと',
        () async {
          final now = DateTime(2026, 10, 25, 10);
          // 初期状態: A(0), B(1), C(2)
          await dao.upsertMemos([
            MemosCompanion.insert(
              id: 'A',
              userId: testUserId,
              title: 'A',
              content: 'A',
              createdAt: now,
              updatedAt: now,
              sortOrder: const Value(0),
            ),
            MemosCompanion.insert(
              id: 'B',
              userId: testUserId,
              title: 'B',
              content: 'B',
              createdAt: now,
              updatedAt: now,
              sortOrder: const Value(1),
            ),
            MemosCompanion.insert(
              id: 'C',
              userId: testUserId,
              title: 'C',
              content: 'C',
              createdAt: now,
              updatedAt: now,
              sortOrder: const Value(2),
            ),
          ]);

          // 1. A を論理削除（sortOrder: 0 をキープ）
          await dao.updateMemo(
            'A',
            testUserId,
            const MemosCompanion(isDeleted: Value(true)),
          );

          // 2. 残りのメモ [C, B] を並び替え（Aの0を避けて C: 1, B: 2 が割り当てられる）
          await dao.updateSortOrders(['C', 'B'], testUserId);

          // 3. A を Undo 復元
          await dao.restoreMemo(
            'A',
            testUserId,
            now.add(const Duration(minutes: 1)),
          );

          final allMemos = await dao.getAllMemos(testUserId);
          check(allMemos.length).equals(3);

          final memoA = allMemos.firstWhere((m) => m.id == 'A');
          final memoC = allMemos.firstWhere((m) => m.id == 'C');
          final memoB = allMemos.firstWhere((m) => m.id == 'B');

          // Aは元の先頭位置（0）で復元され、並び替えたCが1、Bが2となり重複が一切ないこと
          check(memoA.sortOrder).equals(0);
          check(memoC.sortOrder).equals(1);
          check(memoB.sortOrder).equals(2);

          final sortOrders = allMemos.map((m) => m.sortOrder).toSet();
          check(sortOrders.length).equals(3);
        },
      );

      test('【正常系】中間のメモ削除後に残りを並び替えてからUndoした際も元の位置で復元され重複しないこと', () async {
        final now = DateTime(2026, 10, 25, 10);
        // 初期状態: A(0), B(1), C(2)
        await dao.upsertMemos([
          MemosCompanion.insert(
            id: 'A',
            userId: testUserId,
            title: 'A',
            content: 'A',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(0),
          ),
          MemosCompanion.insert(
            id: 'B',
            userId: testUserId,
            title: 'B',
            content: 'B',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(1),
          ),
          MemosCompanion.insert(
            id: 'C',
            userId: testUserId,
            title: 'C',
            content: 'C',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(2),
          ),
        ]);

        // 1. 中間の B を論理削除（sortOrder: 1 をキープ）
        await dao.updateMemo(
          'B',
          testUserId,
          const MemosCompanion(isDeleted: Value(true)),
        );

        // 2. 残りのメモ [C, A] を並び替え（Bの1を避けて C: 0, A: 2 が割り当てられる）
        await dao.updateSortOrders(['C', 'A'], testUserId);

        // 3. B を Undo 復元
        await dao.restoreMemo(
          'B',
          testUserId,
          now.add(const Duration(minutes: 1)),
        );

        final allMemos = await dao.getAllMemos(testUserId);
        check(allMemos.length).equals(3);

        final memoC = allMemos.firstWhere((m) => m.id == 'C');
        final memoB = allMemos.firstWhere((m) => m.id == 'B');
        final memoA = allMemos.firstWhere((m) => m.id == 'A');

        // Cが0、復元されたBが元の位置(1)、Aが2となり、重複が一切ないこと
        check(memoC.sortOrder).equals(0);
        check(memoB.sortOrder).equals(1);
        check(memoA.sortOrder).equals(2);

        final sortOrders = allMemos.map((m) => m.sortOrder).toSet();
        check(sortOrders.length).equals(3);
      });

      test('【正常系】並び替え対象取得後に新規リモートメモが先行マージされても'
          'sortOrderが重複せず順序が保たれること', () async {
        final now = DateTime(2026, 10, 25, 10);
        // 初期状態: A(0), B(1)
        await dao.upsertMemos([
          MemosCompanion.insert(
            id: 'A',
            userId: testUserId,
            title: 'A',
            content: 'A',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(0),
          ),
          MemosCompanion.insert(
            id: 'B',
            userId: testUserId,
            title: 'B',
            content: 'B',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(1),
          ),
        ]);

        // 並び替え処理が古い一覧 ['B', 'A'] を保持している状態で、
        // 先に新規リモートメモ C のマージが完了する
        await dao.mergeRemoteMemos(testUserId, [
          {
            'id': 'C',
            'title': 'C新規',
            'content': 'C新規',
            'createdAt': now.add(const Duration(minutes: 1)),
            'updatedAt': now.add(const Duration(minutes: 1)),
            'isDeleted': false,
          },
        ]);

        // その後、取得済みの古い一覧 ['B', 'A'] による並び替えを実行
        await dao.updateSortOrders(['B', 'A'], testUserId);

        final allMemos = await dao.getAllMemos(testUserId);
        check(allMemos.length).equals(3);

        final memoC = allMemos.firstWhere((m) => m.id == 'C');
        final memoB = allMemos.firstWhere((m) => m.id == 'B');
        final memoA = allMemos.firstWhere((m) => m.id == 'A');

        // 新規メモCが先頭(0)、並び替えられたBが(1)、Aが(2)となり、重複が一切ないこと
        check(memoC.sortOrder).equals(0);
        check(memoB.sortOrder).equals(1);
        check(memoA.sortOrder).equals(2);

        final sortOrders = allMemos.map((m) => m.sortOrder).toSet();
        check(sortOrders.length).equals(3);
      });

      test('【正常系】並び替え一覧取得後に削除が先行反映されても、'
          '削除済みメモの位置が予約され元位置でUndoできること', () async {
        final now = DateTime(2026, 10, 25, 10);
        // 初期状態: A(0), B(1), C(2)
        await dao.upsertMemos([
          MemosCompanion.insert(
            id: 'A',
            userId: testUserId,
            title: 'A',
            content: 'A',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(0),
          ),
          MemosCompanion.insert(
            id: 'B',
            userId: testUserId,
            title: 'B',
            content: 'B',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(1),
          ),
          MemosCompanion.insert(
            id: 'C',
            userId: testUserId,
            title: 'C',
            content: 'C',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(2),
          ),
        ]);

        // 並び替え処理が古い一覧 ['B', 'A', 'C'] を保持している状態で、
        // 先に A の削除が DB に反映される
        await dao.updateMemo(
          'A',
          testUserId,
          const MemosCompanion(isDeleted: Value(true)),
        );

        // その後、取得済みの古い一覧 ['B', 'A', 'C'] による並び替えを実行
        await dao.updateSortOrders(['B', 'A', 'C'], testUserId);

        // A を Undo 復元
        await dao.restoreMemo(
          'A',
          testUserId,
          now.add(const Duration(minutes: 1)),
        );

        final allMemos = await dao.getAllMemos(testUserId);
        check(allMemos.length).equals(3);

        final memoA = allMemos.firstWhere((m) => m.id == 'A');
        final memoB = allMemos.firstWhere((m) => m.id == 'B');
        final memoC = allMemos.firstWhere((m) => m.id == 'C');

        // Aは再採番されず元の位置(0)を維持し、Bが1、Cが2となり重複が一切ないこと
        check(memoA.sortOrder).equals(0);
        check(memoB.sortOrder).equals(1);
        check(memoC.sortOrder).equals(2);

        final sortOrders = allMemos.map((m) => m.sortOrder).toSet();
        check(sortOrders.length).equals(3);
      });

      test('【正常系】mergeRemoteMemosで非文字列ID（null・数値・キー欠損）が混在しても'
          'エラーにならず有効なメモのみ取り込まれること', () async {
        final now = DateTime(2026, 10, 25, 10);
        // 既存メモ m1 を登録
        await dao.insertMemo(
          MemosCompanion.insert(
            id: 'm1',
            userId: testUserId,
            title: 'M1旧',
            content: 'C1旧',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(0),
          ),
        );

        // 非文字列ID（null, int, キー欠損）と有効なメモ（m1更新, m2新規）を混在させてマージ
        await dao.mergeRemoteMemos(testUserId, [
          {
            'id': null,
            'title': '不正null',
            'content': 'C',
            'createdAt': now,
            'updatedAt': now,
            'isDeleted': false,
          },
          {
            'id': 12345,
            'title': '不正int',
            'content': 'C',
            'createdAt': now,
            'updatedAt': now,
            'isDeleted': false,
          },
          {
            'title': 'IDキーなし',
            'content': 'C',
            'createdAt': now,
            'updatedAt': now,
            'isDeleted': false,
          },
          {
            'id': 'm1',
            'title': 'M1更新',
            'content': 'C1更新',
            'createdAt': now,
            'updatedAt': now.add(const Duration(minutes: 5)),
            'isDeleted': false,
          },
          {
            'id': 'm2',
            'title': 'M2新規',
            'content': 'C2新規',
            'createdAt': now,
            'updatedAt': now,
            'isDeleted': false,
          },
        ]);

        // 全件非文字列IDの場合もエラーにならず安全に終了すること
        await dao.mergeRemoteMemos(testUserId, [
          {'id': 999, 'title': '無効のみ'},
        ]);

        final allMemos = await dao.getAllMemos(testUserId);
        check(allMemos.length).equals(2);

        final m1 = await dao.getMemoById('m1', testUserId);
        final m2 = await dao.getMemoById('m2', testUserId);
        check(m1.title).equals('M1更新');
        check(m1.sortOrder).equals(1);
        check(m2.title).equals('M2新規');
        check(m2.sortOrder).equals(0);
      });

      test('【正常系】mergeRemoteMemosで無効な日付のリモートメモや再取得があっても'
          '既存メモのsortOrderがシフトされないこと', () async {
        final now = DateTime(2026, 10, 25, 10);
        // 既存メモ m1(0), m2(1) を登録
        await dao.upsertMemos([
          MemosCompanion.insert(
            id: 'm1',
            userId: testUserId,
            title: 'M1',
            content: 'C1',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(0),
          ),
          MemosCompanion.insert(
            id: 'm2',
            userId: testUserId,
            title: 'M2',
            content: 'C2',
            createdAt: now,
            updatedAt: now,
            sortOrder: const Value(1),
          ),
        ]);

        final invalidDateMemos = <Map<String, dynamic>>[
          {
            'id': 'bad-created',
            'title': '作成日不正',
            'content': 'C',
            'createdAt': 'invalid-date',
            'updatedAt': now,
            'isDeleted': false,
          },
          {
            'id': 'bad-updated',
            'title': '更新日null',
            'content': 'C',
            'createdAt': now,
            'updatedAt': null,
            'isDeleted': false,
          },
          {
            'id': 'missing-date',
            'title': '日付キー欠損',
            'content': 'C',
            'isDeleted': false,
          },
        ];

        // 無効な日付のメモのみを複数回受信（再取得を再現）してもシフトされないこと
        await dao.mergeRemoteMemos(testUserId, invalidDateMemos);
        await dao.mergeRemoteMemos(testUserId, invalidDateMemos);

        var m1 = await dao.getMemoById('m1', testUserId);
        var m2 = await dao.getMemoById('m2', testUserId);
        check(m1.sortOrder).equals(0);
        check(m2.sortOrder).equals(1);
        check((await dao.getAllMemos(testUserId)).length).equals(2);

        // 無効なメモと有効な新規メモ(m3)が混在する場合、有効な1件分だけシフトされること
        final mixedPayload = <Map<String, dynamic>>[
          ...invalidDateMemos,
          {
            'id': 'm3',
            'title': 'M3新規',
            'content': 'C3新規',
            'createdAt': now,
            'updatedAt': now,
            'isDeleted': false,
          },
        ];
        await dao.mergeRemoteMemos(testUserId, mixedPayload);

        // 同じペイロードを再取得しても追加シフトされないこと
        await dao.mergeRemoteMemos(testUserId, mixedPayload);

        m1 = await dao.getMemoById('m1', testUserId);
        m2 = await dao.getMemoById('m2', testUserId);
        final m3 = await dao.getMemoById('m3', testUserId);
        check(m3.sortOrder).equals(0);
        check(m1.sortOrder).equals(1);
        check(m2.sortOrder).equals(2);
        check((await dao.getAllMemos(testUserId)).length).equals(3);
      });
    });
  });
}
