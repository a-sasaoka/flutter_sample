import 'package:drift/drift.dart';
import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/features/memos/data/memo_table.dart';

part 'memos_dao.g.dart';

/// メモに関するデータ操作を担当するクラス
@DriftAccessor(tables: [Memos])
class MemosDao extends DatabaseAccessor<AppDatabase> with _$MemosDaoMixin {
  /// コンストラクタ
  MemosDao(super.attachedDatabase);

  /// すべてのメモを取得する（削除されていないもの）
  Future<List<Memo>> getAllMemos() =>
      (select(memos)..where((t) => t.isDeleted.equals(false))).get();

  /// メモをIDで1件取得する
  Future<Memo> getMemoById(String id) =>
      (select(memos)..where((t) => t.id.equals(id))).getSingle();

  /// メモを追加する
  Future<void> insertMemo(MemosCompanion memo) => into(memos).insert(memo);

  /// メモを更新する
  Future<void> updateMemo(String id, MemosCompanion memo) =>
      (update(memos)..where((t) => t.id.equals(id))).write(memo);

  /// 同期が必要なメモ（isSynced = false）を取得する
  Future<List<Memo>> getUnsyncedMemos() =>
      (select(memos)..where((t) => t.isSynced.equals(false))).get();

  /// 指定したIDリストに含まれるメモを取得する
  Future<List<Memo>> getMemosByIds(List<String> ids) =>
      (select(memos)..where((t) => t.id.isIn(ids))).get();

  /// 指定したIDリストのメモの同期状態を一括更新する
  Future<void> updateSyncStatus(List<String> ids, {required bool isSynced}) =>
      (update(memos)..where((t) => t.id.isIn(ids))).write(
        MemosCompanion(isSynced: Value(isSynced)),
      );

  /// 複数のメモを一括で挿入または更新する
  Future<void> upsertMemos(List<MemosCompanion> companions) async {
    await batch((batch) {
      batch.insertAll(
        memos,
        companions,
        mode: InsertMode.insertOrReplace,
      );
    });
  }
}
