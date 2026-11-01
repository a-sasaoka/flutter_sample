import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/features/memos/data/memo_table.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';

part 'memos_dao.g.dart';

/// メモに関するデータ操作を担当するクラス
@DriftAccessor(tables: [Memos])
class MemosDao extends DatabaseAccessor<AppDatabase> with _$MemosDaoMixin {
  /// コンストラクタ
  MemosDao(super.attachedDatabase);

  /// 指定したユーザーのすべてのメモを取得する（削除されていないもの）
  Future<List<Memo>> getAllMemos(String userId) => (select(
    memos,
  )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))).get();

  /// 指定したユーザーのすべてのメモの変更を監視する（削除されていないもの）
  Stream<List<Memo>> watchAllMemos(String userId) => (select(
    memos,
  )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))).watch();

  /// SQLiteの既定のLIKEパターン上限バイト数（50,000バイト）
  /// この上限を超えるLIKEクエリは「LIKE or GLOB pattern too complex」エラーとなるため抑止する
  static const int _maxLikePatternBytes = 50000;

  static String? _escapeLikePattern(String input) {
    final escaped = input
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_')
        .toLowerCase();
    final pattern = '%$escaped%';
    if (utf8.encode(pattern).length > _maxLikePatternBytes) {
      return null;
    }
    return pattern;
  }

  /// 指定したユーザーのメモをキーワード・カテゴリ・未同期条件で絞り込んで監視する
  Stream<List<Memo>> watchFilteredMemos(
    String userId, {
    String? query,
    MemoCategory? category,
    bool? unsyncedOnly,
  }) {
    return (select(memos)..where((t) {
          var predicate = t.userId.equals(userId) & t.isDeleted.equals(false);
          final trimmedQuery = query?.trim();
          if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
            final pattern = _escapeLikePattern(trimmedQuery);
            if (pattern == null) {
              predicate = predicate & const Constant(false);
            } else {
              predicate =
                  predicate &
                  (t.title.lower().like(pattern, escapeChar: r'\') |
                      t.content.lower().like(pattern, escapeChar: r'\'));
            }
          }
          if (category != null) {
            predicate = predicate & t.category.equals(category.name);
          }
          if (unsyncedOnly == true) {
            predicate = predicate & t.isSynced.equals(false);
          }
          return predicate;
        }))
        .watch();
  }

  /// 指定したユーザーのメモをキーワード・カテゴリ・未同期条件で絞り込んで取得する
  Future<List<Memo>> getFilteredMemos(
    String userId, {
    String? query,
    MemoCategory? category,
    bool? unsyncedOnly,
  }) {
    return (select(memos)..where((t) {
          var predicate = t.userId.equals(userId) & t.isDeleted.equals(false);
          final trimmedQuery = query?.trim();
          if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
            final pattern = _escapeLikePattern(trimmedQuery);
            if (pattern == null) {
              predicate = predicate & const Constant(false);
            } else {
              predicate =
                  predicate &
                  (t.title.lower().like(pattern, escapeChar: r'\') |
                      t.content.lower().like(pattern, escapeChar: r'\'));
            }
          }
          if (category != null) {
            predicate = predicate & t.category.equals(category.name);
          }
          if (unsyncedOnly == true) {
            predicate = predicate & t.isSynced.equals(false);
          }
          return predicate;
        }))
        .get();
  }

  /// メモをIDとユーザーIDで1件取得する
  Future<Memo> getMemoById(String id, String userId) => (select(
    memos,
  )..where((t) => t.id.equals(id) & t.userId.equals(userId))).getSingle();

  /// メモを追加する
  Future<void> insertMemo(MemosCompanion memo) => into(memos).insert(memo);

  /// メモを更新する（所有ユーザーのもののみ）
  Future<void> updateMemo(String id, String userId, MemosCompanion memo) =>
      (update(
        memos,
      )..where((t) => t.id.equals(id) & t.userId.equals(userId))).write(memo);

  /// 指定したユーザーの同期が必要なメモ（isSynced = false）を取得する
  Future<List<Memo>> getUnsyncedMemos(String userId) => (select(
    memos,
  )..where((t) => t.userId.equals(userId) & t.isSynced.equals(false))).get();

  /// 指定したユーザーの指定IDリストに含まれるメモを取得する
  Future<List<Memo>> getMemosByIds(List<String> ids, String userId) => (select(
    memos,
  )..where((t) => t.id.isIn(ids) & t.userId.equals(userId))).get();

  /// 指定したユーザーのメモの同期状態を一括更新する
  Future<void> updateSyncStatus(
    List<String> ids,
    String userId, {
    required bool isSynced,
  }) => (update(memos)..where((t) => t.id.isIn(ids) & t.userId.equals(userId)))
      .write(MemosCompanion(isSynced: Value(isSynced)));

  /// 複数のメモを一括で挿入または更新する
  Future<void> upsertMemos(List<MemosCompanion> companions) async {
    await batch((batch) {
      batch.insertAll(memos, companions, mode: InsertMode.insertOrReplace);
    });
  }

  /// 新規メモを先頭に追加するため、既存の有効なメモの並び順を1つずつ後ろにずらす
  Future<void> shiftSortOrders(String userId) async {
    await customUpdate(
      'UPDATE memos SET sort_order = sort_order + 1 '
      'WHERE user_id = ? AND is_deleted = 0;',
      variables: [Variable.withString(userId)],
      updates: {memos},
    );
  }

  /// 新規メモを先頭（sortOrder: 0）に追加し、既存の有効なメモを1つずつ後ろにずらす
  /// トランザクション内でアトミックに実行されるため、変更通知は1回のみ発行されます
  Future<void> insertMemoWithShift(String userId, MemosCompanion memo) async {
    await transaction(() async {
      await shiftSortOrders(userId);
      await insertMemo(memo);
    });
  }

  /// 指定したユーザーのメモの並び順（sortOrder）を一括更新する
  Future<void> updateSortOrders(
    Map<String, int> idToOrderMap,
    String userId,
  ) async {
    await transaction(() async {
      for (final entry in idToOrderMap.entries) {
        await (update(memos)
              ..where((t) => t.id.equals(entry.key) & t.userId.equals(userId)))
            .write(MemosCompanion(sortOrder: Value(entry.value)));
      }
    });
  }

  /// 削除されたメモを復元する（論理削除フラグを解除して未同期状態にする）
  Future<void> restoreMemo(String id, String userId, DateTime updatedAt) =>
      (update(
        memos,
      )..where((t) => t.id.equals(id) & t.userId.equals(userId))).write(
        MemosCompanion(
          isDeleted: const Value(false),
          updatedAt: Value(updatedAt),
          isSynced: const Value(false),
        ),
      );
}
