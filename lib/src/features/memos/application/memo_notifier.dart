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
  Future<void> addMemo(String title, String content) async {
    final repository = ref.read(memoRepositoryProvider);
    await repository.addMemo(title, content);
    ref.invalidateSelf();
  }

  /// メモを削除する
  Future<void> deleteMemo(String id) async {
    final repository = ref.read(memoRepositoryProvider);
    await repository.deleteMemo(id);
    ref.invalidateSelf();
  }

  /// 手動同期を実行する
  Future<void> sync() async {
    final repository = ref.read(memoRepositoryProvider);
    await repository.syncUnsentMemos();
    ref.invalidateSelf();
  }
}
