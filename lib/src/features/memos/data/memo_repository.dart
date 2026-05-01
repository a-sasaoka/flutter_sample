import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:flutter_sample/src/core/database/database_provider.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'memo_repository.g.dart';

/// メモ（Memo）のデータをデータベースに保存したり、取り出したりするためのリポジトリ
class MemoRepository {
  /// コンストラクタ
  MemoRepository(this._ref, this._db);
  final Ref _ref;
  final AppDatabase _db;

  /// 新しいメモをデータベースに追加する
  ///
  /// [title]にメモのタイトル、[content]にメモの本文を渡す
  /// 保存された時間は、今の時間を自動的に設定する
  Future<void> addMemo(String title, String content) async {
    await _db
        .into(_db.memos)
        .insert(
          MemosCompanion.insert(
            title: title,
            content: content,
            createdAt: _ref.read(currentDateTimeProvider),
          ),
        );
  }

  /// データベースに保存されているすべてのメモを一覧（リスト）として取得する
  Future<List<MemoModel>> getAllMemos() async {
    // データベースからデータを取り出す
    final driftMemos = await _db.select(_db.memos).get();

    // MemoModelに詰め替える
    return driftMemos
        .map(
          (memo) => MemoModel(
            id: memo.id,
            title: memo.title,
            content: memo.content,
            createdAt: memo.createdAt,
          ),
        )
        .toList();
  }
}

/// アプリ全体で[MemoRepository]を使えるようにするためのプロバイダー
@riverpod
MemoRepository memoRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return MemoRepository(ref, db);
}
