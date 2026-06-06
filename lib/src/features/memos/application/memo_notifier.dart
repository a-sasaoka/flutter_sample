import 'dart:async';

import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
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
  Stream<List<MemoModel>> build() {
    final repository = ref.watch(memoRepositoryProvider);

    // オンライン時はバックグラウンドで未送信データの同期とリモートデータの取得を行う
    if (ref.watch(isOnlineProvider)) {
      unawaited(_syncAndFetch(repository));
    }

    // データベースから全てのメモを取得する（変更を監視）
    final allMemosStream = repository.watchAllMemos();

    // 検索クエリとソートの現在の状態を監視（watch）します
    final searchQuery = ref.watch(memoSearchQueryProvider).trim().toLowerCase();
    final sortOrder = ref.watch(memoSortOrderStateProvider);

    return allMemosStream.map((allMemos) {
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
        filteredMemos = [...allMemos];
      }

      // 2. 指定されたルールに基づいて並び替える
      final comparator = switch (sortOrder) {
        MemoSortOrder.createdAtDesc =>
          (MemoModel a, MemoModel b) => b.createdAt.compareTo(a.createdAt),
        MemoSortOrder.createdAtAsc =>
          (MemoModel a, MemoModel b) => a.createdAt.compareTo(b.createdAt),
        MemoSortOrder.updatedAtDesc =>
          (MemoModel a, MemoModel b) => b.updatedAt.compareTo(a.updatedAt),
        MemoSortOrder.updatedAtAsc =>
          (MemoModel a, MemoModel b) => a.updatedAt.compareTo(b.updatedAt),
        MemoSortOrder.titleAsc =>
          (MemoModel a, MemoModel b) => a.title.compareTo(
            b.title,
          ),
        MemoSortOrder.titleDesc =>
          (MemoModel a, MemoModel b) => b.title.compareTo(a.title),
      };
      filteredMemos.sort(comparator);

      return filteredMemos;
    });
  }

  /// 非同期でサーバーとのデータ同期およびマージを実行する
  Future<void> _syncAndFetch(MemoRepository repository) async {
    try {
      await repository.fetchAndMergeRemoteMemos();
    } on Exception catch (e, st) {
      // 💡 エラーが発生しても画面の操作を邪魔しないよう、Talker（ログ）への記録のみにとどめます
      ref
          .read(loggerProvider)
          .error(
            'バックグラウンド同期中にエラーが発生しました',
            e,
            st,
          );
    }
  }

  /// 新しいメモを追加する
  Future<void> addMemo(String title, String content) async {
    final repository = ref.read(memoRepositoryProvider);
    await repository.addMemo(title, content);
  }

  /// メモを削除する
  Future<void> deleteMemo(String id) async {
    final repository = ref.read(memoRepositoryProvider);
    await repository.deleteMemo(id);
  }

  /// 手動同期を実行する
  Future<void> sync() async {
    final repository = ref.read(memoRepositoryProvider);
    if (ref.read(isOnlineProvider)) {
      await repository.fetchAndMergeRemoteMemos();
    }
  }
}
