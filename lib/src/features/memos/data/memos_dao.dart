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

  /// リモートデータをローカルDBにマージする（読み取りから書き込みまでをトランザクションで直列化・原子化）
  Future<void> mergeRemoteMemos(
    String userId,
    List<Map<String, dynamic>> remoteData,
  ) async {
    await transaction(() async {
      final ids = remoteData.map((e) => e['id'] as String).toList();
      final localMemos = await getMemosByIds(ids, userId);
      final localMemosMap = {for (final m in localMemos) m.id: m};
      final companionsToUpsert = <MemosCompanion>[];

      // リモートデータのうち、ローカルに存在しない新規メモの件数をカウント
      var newMemoCount = 0;
      for (final remoteMemo in remoteData) {
        if (remoteMemo case {'id': final String id}) {
          if (!localMemosMap.containsKey(id)) {
            newMemoCount++;
          }
        }
      }

      // 新規リモートメモが存在する場合、既存メモ（削除済み含む）を新規件数分シフト
      if (newMemoCount > 0) {
        await shiftSortOrders(userId, newMemoCount);
      }

      var newMemoIndex = 0;

      for (final remoteMemo in remoteData) {
        if (remoteMemo case {
          'id': final String id,
          'title': final String title,
          'content': final String content,
          'createdAt': final DateTime createdAt,
          'updatedAt': final DateTime updatedAt,
          'isDeleted': final bool isDeleted,
        }) {
          final localMemo = localMemosMap[id];

          // サーバーのデータが新しい場合、またはローカルに存在しない場合に更新/挿入対象とする
          if (localMemo == null || updatedAt.isAfter(localMemo.updatedAt)) {
            final int sortOrder;
            if (localMemo != null) {
              // 既存メモは shiftSortOrders でシフトされた後の値を維持する
              sortOrder = newMemoCount > 0
                  ? localMemo.sortOrder + newMemoCount
                  : localMemo.sortOrder;
            } else {
              // 新規リモートメモは先頭（0, 1, ..., newMemoCount - 1）に配置
              sortOrder = newMemoIndex;
              newMemoIndex++;
            }

            companionsToUpsert.add(
              MemosCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: Value(isDeleted),
                isSynced: const Value(true),
                category: Value(localMemo?.category),
                sortOrder: Value(sortOrder),
              ),
            );
          }
        }
      }

      if (companionsToUpsert.isNotEmpty) {
        await batch((batch) {
          batch.insertAll(
            memos,
            companionsToUpsert,
            mode: InsertMode.insertOrReplace,
          );
        });
      }
    });
  }

  /// 新規メモを先頭に追加するため、既存メモ（削除済み・Undo復元対象を含む）の並び順を後ろにずらす
  Future<void> shiftSortOrders(String userId, [int shiftCount = 1]) async {
    await customUpdate(
      'UPDATE memos SET sort_order = sort_order + ? '
      'WHERE user_id = ?;',
      variables: [Variable.withInt(shiftCount), Variable.withString(userId)],
      updates: {memos},
    );
  }

  /// 新規メモを先頭（sortOrder: 0）に追加し、既存のメモ（削除済み含む）を1つずつ後ろにずらす
  /// トランザクション内でアトミックに実行されるため、変更通知は1回のみ発行されます
  Future<void> insertMemoWithShift(String userId, MemosCompanion memo) async {
    await transaction(() async {
      await shiftSortOrders(userId);
      await insertMemo(memo.copyWith(sortOrder: const Value(0)));
    });
  }

  /// 指定したユーザーのメモの並び順（sortOrder）を一括更新する
  /// 並び替え対象外のメモ（削除済みメモや先行マージされた新規メモ）の位置を保持し、
  /// それらを避けて空いている番号を一意に割り当てます
  Future<void> updateSortOrders(List<String> orderedIds, String userId) async {
    await transaction(() async {
      // ユーザーの全メモを取得（削除済み含む）
      final allMemos = await (select(
        memos,
      )..where((t) => t.userId.equals(userId))).get();
      final allMemosMap = {for (final m in allMemos) m.id: m};

      // 並び替え対象外のメモ（削除済みメモや先行マージされた新規メモ）の番号を
      // 「予約席」として保持し、番号を変更しない
      final reservedOrders = <int>{};
      for (final memo in allMemos) {
        if (!orderedIds.contains(memo.id)) {
          reservedOrders.add(memo.sortOrder);
        }
      }

      final idToNewOrderMap = <String, int>{};
      var currentOrder = 0;

      // 並び替えたメモには、予約席（削除済みメモの元の位置など）を避けて
      // 空いている番号を順番に割り当てる
      for (final id in orderedIds) {
        if (!allMemosMap.containsKey(id)) {
          continue;
        }
        // 予約されている番号はスキップ
        while (reservedOrders.contains(currentOrder)) {
          currentOrder++;
        }
        idToNewOrderMap[id] = currentOrder;
        currentOrder++;
      }

      // 変更があったメモのみDBを更新
      for (final entry in idToNewOrderMap.entries) {
        final currentMemo = allMemosMap[entry.key];
        if (currentMemo != null && currentMemo.sortOrder != entry.value) {
          await (update(
                memos,
              )..where((t) => t.id.equals(entry.key) & t.userId.equals(userId)))
              .write(MemosCompanion(sortOrder: Value(entry.value)));
        }
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
