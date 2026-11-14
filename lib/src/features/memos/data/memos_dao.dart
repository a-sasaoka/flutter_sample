import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/features/memos/data/memo_table.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';

part 'memos_dao.g.dart';

typedef _ValidatedRemoteMemo = ({
  String id,
  String title,
  String content,
  DateTime createdAt,
  DateTime updatedAt,
  bool isDeleted,
});

/// メモに関するデータ操作を担当するクラス
@DriftAccessor(tables: [Memos])
class MemosDao extends DatabaseAccessor<AppDatabase> with _$MemosDaoMixin {
  /// コンストラクタ
  MemosDao(super.attachedDatabase);

  var _mutationSeq = 0;
  final Map<(String, String), int> _memoMutationSeqs = {};

  /// ローカルDB書き込みごとに単調増加する現在の変更シーケンスを返す
  int get currentMutationSeq => _mutationSeq;

  void _markMemoMutated(String userId, String id) {
    _memoMutationSeqs[(userId, id)] = ++_mutationSeq;
  }

  void _markCompanionMutated(MemosCompanion memo) {
    if (memo.id.present) {
      _markMemoMutated(
        memo.userId.present ? memo.userId.value : '',
        memo.id.value,
      );
    }
  }

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

  MemosCompanion _withUpdatedAtMicros(MemosCompanion memo) {
    if (memo.updatedAtMicros.present || !memo.updatedAt.present) {
      return memo;
    }
    return memo.copyWith(
      updatedAtMicros: Value(memo.updatedAt.value.microsecondsSinceEpoch),
    );
  }

  int _localUpdatedAtMicros(Memo memo) =>
      memo.updatedAtMicros ?? memo.updatedAt.microsecondsSinceEpoch;

  /// メモを追加する
  Future<void> insertMemo(MemosCompanion memo) async {
    await into(memos).insert(_withUpdatedAtMicros(memo));
    _markCompanionMutated(memo);
  }

  /// メモを更新する（所有ユーザーのもののみ）
  Future<void> updateMemo(String id, String userId, MemosCompanion memo) async {
    await (update(memos)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .write(_withUpdatedAtMicros(memo));
    _markMemoMutated(userId, id);
  }

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
  }) async {
    await (update(memos)
          ..where((t) => t.id.isIn(ids) & t.userId.equals(userId)))
        .write(MemosCompanion(isSynced: Value(isSynced)));
    for (final id in ids) {
      _markMemoMutated(userId, id);
    }
  }

  /// 複数のメモを一括で挿入または更新する
  Future<void> upsertMemos(List<MemosCompanion> companions) async {
    await batch((batch) {
      batch.insertAll(
        memos,
        companions.map(_withUpdatedAtMicros).toList(),
        mode: InsertMode.insertOrReplace,
      );
    });
    companions.forEach(_markCompanionMutated);
  }

  /// リモートデータをローカルDBにマージする（読み取りから書き込みまでをトランザクションで直列化・原子化）
  Future<void> mergeRemoteMemos(
    String userId,
    List<Map<String, dynamic>> remoteData, {
    int? fetchedBeforeSeq,
  }) async {
    await transaction(() async {
      // 型・日付検証を通過したメモをIDごとに統合し、重複IDは updatedAt が最新の版のみ残す
      final latestRemoteMemosById = <String, _ValidatedRemoteMemo>{};
      for (final remoteMemo in remoteData) {
        if (remoteMemo case {
          'id': final String id,
          'title': final String title,
          'content': final String content,
          'createdAt': final DateTime createdAt,
          'updatedAt': final DateTime updatedAt,
          'isDeleted': final bool isDeleted,
        }) {
          final existing = latestRemoteMemosById[id];
          if (existing == null || updatedAt.isAfter(existing.updatedAt)) {
            latestRemoteMemosById[id] = (
              id: id,
              title: title,
              content: content,
              createdAt: createdAt,
              updatedAt: updatedAt,
              isDeleted: isDeleted,
            );
          }
        }
      }
      if (latestRemoteMemosById.isEmpty) {
        return;
      }

      final ids = latestRemoteMemosById.keys.toList();
      final localMemos = await getMemosByIds(ids, userId);
      final localMemosMap = {for (final m in localMemos) m.id: m};
      final companionsToUpsert = <MemosCompanion>[];

      // 重複排除済みデータのうち、ローカルに存在しない新規メモのみをカウント
      final newMemoCount = latestRemoteMemosById.values
          .where((memo) => !localMemosMap.containsKey(memo.id))
          .length;

      // 新規リモートメモが存在する場合、既存メモ（削除済み含む）を新規件数分シフト
      if (newMemoCount > 0) {
        await shiftSortOrders(userId, newMemoCount);
      }

      var newMemoIndex = 0;

      for (final memo in latestRemoteMemosById.values) {
        final localMemo = localMemosMap[memo.id];
        final remoteMicros = memo.updatedAt.microsecondsSinceEpoch;

        final bool shouldUpsert;
        if (localMemo == null) {
          shouldUpsert = true;
        } else {
          final localMicros = _localUpdatedAtMicros(localMemo);
          final hasDiff =
              localMemo.isDeleted != memo.isDeleted ||
              localMemo.title != memo.title ||
              localMemo.content != memo.content;
          final modifiedDuringFetch =
              fetchedBeforeSeq != null &&
              (_memoMutationSeqs[(userId, memo.id)] ?? 0) > fetchedBeforeSeq;
          // サーバーのデータが新しい場合（マイクロ秒比較）に更新対象とする。
          // 同一タイムスタンプの場合は同期済みかつ内容・削除状態に差分があり、
          // かつ取得開始後にローカル変更・同期完了が発生していない場合のみ取り込む。
          shouldUpsert =
              remoteMicros > localMicros ||
              (remoteMicros == localMicros &&
                  localMemo.isSynced &&
                  hasDiff &&
                  !modifiedDuringFetch);
        }

        if (shouldUpsert) {
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
              id: memo.id,
              userId: userId,
              title: memo.title,
              content: memo.content,
              createdAt: memo.createdAt,
              updatedAt: memo.updatedAt,
              updatedAtMicros: Value(remoteMicros),
              isDeleted: Value(memo.isDeleted),
              isSynced: const Value(true),
              category: Value(localMemo?.category),
              sortOrder: Value(sortOrder),
            ),
          );
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
        for (final companion in companionsToUpsert) {
          _markMemoMutated(userId, companion.id.value);
        }
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
      // ループ内でリスト照合を繰り返さないよう、事前にSetへ変換する
      final orderedIdSet = orderedIds.toSet();

      // 並び替え対象外のメモ、または「DB上で削除済みのメモ」の位置を
      // 予約席として保持し、番号を変更しない
      final reservedOrders = <int>{};
      for (final memo in allMemos) {
        if (!orderedIdSet.contains(memo.id) || memo.isDeleted) {
          reservedOrders.add(memo.sortOrder);
        }
      }

      final idToNewOrderMap = <String, int>{};
      var currentOrder = 0;

      // 並び替えた有効なメモにのみ、予約席を避けて空いている番号を順番に割り当てる
      for (final id in orderedIds) {
        final memo = allMemosMap[id];
        // 存在しないメモ、または DB 上で削除済みのメモは再採番から除外
        if (memo == null || memo.isDeleted) {
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
  Future<void> restoreMemo(String id, String userId, DateTime updatedAt) async {
    await (update(
      memos,
    )..where((t) => t.id.equals(id) & t.userId.equals(userId))).write(
      MemosCompanion(
        isDeleted: const Value(false),
        updatedAt: Value(updatedAt),
        updatedAtMicros: Value(updatedAt.microsecondsSinceEpoch),
        isSynced: const Value(false),
      ),
    );
    _markMemoMutated(userId, id);
  }

  /// 送信した内容と現在のローカルレコードが一致する場合のみ isSynced を true に更新する
  Future<void> markAsSyncedIfUnchanged({
    required String id,
    required String userId,
    required String title,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isDeleted,
  }) async {
    final updatedRows =
        await (update(memos)..where(
              (t) =>
                  t.id.equals(id) &
                  t.userId.equals(userId) &
                  t.title.equals(title) &
                  t.content.equals(content) &
                  t.createdAt.equals(createdAt) &
                  t.updatedAt.equals(updatedAt) &
                  (t.updatedAtMicros.equals(updatedAt.microsecondsSinceEpoch) |
                      t.updatedAtMicros.isNull()) &
                  t.isDeleted.equals(isDeleted),
            ))
            .write(const MemosCompanion(isSynced: Value(true)));
    if (updatedRows > 0) {
      _markMemoMutated(userId, id);
    }
  }
}
