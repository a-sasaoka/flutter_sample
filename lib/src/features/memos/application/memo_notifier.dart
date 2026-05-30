import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_sort_order.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'memo_notifier.g.dart';

/// 検索クエリ（キーワード）を管理するためのプロバイダー（状態管理）
@riverpod
class MemoSearchQuery extends _$MemoSearchQuery {
  @override
  String build() => '';

  /// キーワードを更新します
  // ignore: use_setters_to_change_properties
  void setQuery(String query) => state = query;
}

/// 並び替え（ソート）ルールを管理するためのプロバイダー（状態管理）
@riverpod
class MemoSortOrderState extends _$MemoSortOrderState {
  @override
  MemoSortOrder build() => MemoSortOrder.createdAtDesc;

  /// ルールを更新します
  // ignore: use_setters_to_change_properties
  void setSortOrder(MemoSortOrder sortOrder) => state = sortOrder;
}

/// メモ一覧のデータ（状態）を管理するためのクラス
@riverpod
class MemoNotifier extends _$MemoNotifier {
  @override
  Future<List<MemoModel>> build() async {
    // データベースから全てのメモを取得する（変更を監視）
    final allMemos = await ref.watch(memoRepositoryProvider).getAllMemos();

    // 検索クエリとソートの現在の状態を監視（watch）します
    final searchQuery = ref.watch(memoSearchQueryProvider).trim().toLowerCase();
    final sortOrder = ref.watch(memoSortOrderStateProvider);

    // 1. 検索キーワードによる絞り込み（部分一致）
    var filteredMemos = allMemos;
    if (searchQuery.isNotEmpty) {
      filteredMemos = allMemos.where((memo) {
        final title = memo.title.toLowerCase();
        final content = memo.content.toLowerCase();
        return title.contains(searchQuery) || content.contains(searchQuery);
      }).toList();
    } else {
      // 破壊的変更（sort）を避けるためにリストをコピーする
      filteredMemos = List.from(allMemos);
    }

    // 2. 指定されたルールに基づいて並び替える
    switch (sortOrder) {
      case MemoSortOrder.createdAtDesc:
        filteredMemos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case MemoSortOrder.createdAtAsc:
        filteredMemos.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case MemoSortOrder.updatedAtDesc:
        filteredMemos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case MemoSortOrder.updatedAtAsc:
        filteredMemos.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case MemoSortOrder.titleAsc:
        filteredMemos.sort((a, b) => a.title.compareTo(b.title));
      case MemoSortOrder.titleDesc:
        filteredMemos.sort((a, b) => b.title.compareTo(a.title));
    }

    return filteredMemos;
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
