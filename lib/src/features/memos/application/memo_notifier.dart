import 'dart:async';

import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/memos/application/memo_filter_notifier.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_sort_order.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:flutter_sample/src/features/memos/application/memo_filter_notifier.dart';

part 'memo_notifier.g.dart';

/// メモ一覧のデータ（状態）を管理するためのクラス
@riverpod
class MemoNotifier extends _$MemoNotifier {
  bool _hasSyncedOnInitialOnline = false;

  @override
  Stream<List<MemoModel>> build() {
    final userId = ref.watch(currentUserIdProvider);

    // 未ログイン時は空リストを返し、初期同期フラグもリセット
    if (userId == null) {
      _hasSyncedOnInitialOnline = false;
      return Stream.value([]);
    }

    final repository = ref.watch(memoRepositoryProvider);

    // オンライン時はバックグラウンドで未送信データの同期とリモートデータの取得を行う
    if (!_hasSyncedOnInitialOnline && ref.watch(isOnlineProvider)) {
      _hasSyncedOnInitialOnline = true;
      unawaited(_syncAndFetch(repository, userId));
    }

    // 検索・絞り込み条件を監視します
    final filter = ref.watch(memoFilterProvider);

    // データベースから条件に合致するメモをストリームで監視します
    final memosStream = filter.hasActiveFilter
        ? repository.watchFilteredMemos(
            userId,
            query: filter.query,
            category: filter.category,
            unsyncedOnly: filter.unsyncedOnly ? true : null,
          )
        : repository.watchAllMemos(userId);

    return memosStream.map((filteredMemos) {
      // 破壊的変更を避けるためにリストをコピーしてソート
      final sortedMemos = [...filteredMemos];

      final comparator = switch (filter.sortOrder) {
        MemoSortOrder.createdAtDesc =>
          (MemoModel a, MemoModel b) => b.createdAt.compareTo(a.createdAt),
        MemoSortOrder.createdAtAsc =>
          (MemoModel a, MemoModel b) => a.createdAt.compareTo(b.createdAt),
        MemoSortOrder.updatedAtDesc =>
          (MemoModel a, MemoModel b) => b.updatedAt.compareTo(a.updatedAt),
        MemoSortOrder.updatedAtAsc =>
          (MemoModel a, MemoModel b) => a.updatedAt.compareTo(b.updatedAt),
        MemoSortOrder.titleAsc =>
          (MemoModel a, MemoModel b) => a.title.compareTo(b.title),
        MemoSortOrder.titleDesc =>
          (MemoModel a, MemoModel b) => b.title.compareTo(a.title),
        MemoSortOrder.custom =>
          (MemoModel a, MemoModel b) => a.sortOrder.compareTo(b.sortOrder),
      };
      sortedMemos.sort(comparator);

      return sortedMemos;
    });
  }

  /// 非同期でサーバーとのデータ同期およびマージを実行する
  Future<void> _syncAndFetch(MemoRepository repository, String userId) async {
    try {
      await repository.fetchAndMergeRemoteMemos(userId);
    } on Exception catch (e, st) {
      ref.read(loggerProvider).handle(e, st, 'バックグラウンド同期中にエラーが発生しました');
    }
  }

  /// 新しいメモを追加する
  Future<void> addMemo(
    String title,
    String content, {
    MemoCategory? category,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    final repository = ref.read(memoRepositoryProvider);
    await repository.addMemo(title, content, userId, category: category);
  }

  /// メモを削除する
  Future<void> deleteMemo(String id) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    final repository = ref.read(memoRepositoryProvider);
    await repository.deleteMemo(id, userId);
  }

  /// 削除されたメモを復元（Undo）する
  Future<void> restoreMemo(String id) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    final repository = ref.read(memoRepositoryProvider);
    await repository.restoreMemo(id, userId);
  }

  /// メモの並び順（ドラッグ＆ドロップ）を更新する（Optimistic UI対応）
  Future<void> reorderMemos(int oldIndex, int newIndex) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    final currentMemos = state.asData?.value;
    if (currentMemos == null || currentMemos.isEmpty) {
      return;
    }

    // 検索・絞り込み中は手動並び替え不可
    final filter = ref.read(memoFilterProvider);
    if (filter.hasActiveFilter) {
      return;
    }

    final targetIndex = newIndex;
    if (oldIndex == targetIndex) {
      return;
    }

    // 画面のチラつき（DriftのStreamラグ）を防ぐため、即座にローカル状態（state）を並び替える（Optimistic UI）
    final updatedMemos = [...currentMemos];
    final movedItem = updatedMemos.removeAt(oldIndex);
    updatedMemos.insert(targetIndex, movedItem);
    state = AsyncData(updatedMemos);

    final repository = ref.read(memoRepositoryProvider);
    final orderedIds = updatedMemos.map((m) => m.id).toList();

    try {
      await repository.updateSortOrders(orderedIds, userId);

      // 保存成功後に、ソート順を「カスタム順（手動並び順）」に切り替える
      if (ref.read(memoFilterProvider).sortOrder != MemoSortOrder.custom) {
        ref
            .read(memoFilterProvider.notifier)
            .setSortOrder(MemoSortOrder.custom);
      }
    } on Exception catch (e, st) {
      // 失敗した場合は元の順序にロールバック
      state = AsyncData(currentMemos);
      ref.read(loggerProvider).handle(e, st, 'メモの並び替え保存に失敗しました');
      rethrow;
    }
  }

  /// 手動同期を実行する
  Future<void> sync() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    final repository = ref.read(memoRepositoryProvider);
    if (ref.read(isOnlineProvider)) {
      await repository.fetchAndMergeRemoteMemos(userId);
    }
  }
}
