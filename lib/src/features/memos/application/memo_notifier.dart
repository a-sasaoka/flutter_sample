import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'memo_notifier.g.dart';

/// メモ一覧のデータ（状態）を管理するためのクラス
@riverpod
class MemoNotifier extends _$MemoNotifier {
  @override
  Future<List<MemoModel>> build() async {
    // 全てのメモを取得する
    return ref.watch(memoRepositoryProvider).getAllMemos();
  }

  /// 新しいメモを追加する
  ///
  /// [title] はメモのタイトル、[content] はメモの中身
  Future<void> addMemo(String title, String content) async {
    final repository = ref.read(memoRepositoryProvider);

    // データベースにメモを保存
    await repository.addMemo(title, content);

    // 状態を更新（最新のメモ一覧を再取得）
    ref.invalidateSelf();
  }
}
