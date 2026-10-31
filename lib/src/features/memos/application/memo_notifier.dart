import 'dart:async';

import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_filter_state.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_sort_order.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'memo_notifier.g.dart';

/// 🔍 メモ一覧の検索・絞り込み・ソート条件を管理するプロバイダー
@riverpod
class MemoFilterNotifier extends _$MemoFilterNotifier {
  @override
  MemoFilterState build() => const MemoFilterState();

  /// 検索キーワードを更新します
  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  /// 選択カテゴリを切り替えます（同じカテゴリを再選択した場合は未設定に戻します）
  void toggleCategory(MemoCategory category) {
    if (state.category == category) {
      state = state.copyWith(category: null);
    } else {
      state = state.copyWith(category: category);
    }
  }

  /// カテゴリを設定します
  void setCategory(MemoCategory? category) {
    state = state.copyWith(category: category);
  }

  /// 未同期のみフラグを切り替えます
  void toggleUnsyncedOnly() {
    state = state.copyWith(unsyncedOnly: !state.unsyncedOnly);
  }

  /// 未同期のみフラグを設定します
  void setUnsyncedOnly({required bool unsyncedOnly}) {
    state = state.copyWith(unsyncedOnly: unsyncedOnly);
  }

  /// 並び替え順を更新します
  void setSortOrder(MemoSortOrder sortOrder) {
    state = state.copyWith(sortOrder: sortOrder);
  }

  /// 検索・絞り込み条件を一括リセット（初期化）します（ソート順は維持）
  void resetFilter() {
    state = state.copyWith(query: '', category: null, unsyncedOnly: false);
  }
}

/// 検索クエリ（キーワード）を管理するためのプロバイダー（後方互換性用）
@riverpod
class MemoSearchQuery extends _$MemoSearchQuery {
  @override
  String build() {
    return ref.watch(memoFilterProvider).query;
  }

  /// キーワードを更新します
  void setQuery(String query) {
    ref.read(memoFilterProvider.notifier).setQuery(query);
  }
}

/// 並び替え（ソート）ルールを管理するためのプロバイダー（後方互換性用）
@riverpod
class MemoSortOrderState extends _$MemoSortOrderState {
  @override
  MemoSortOrder build() {
    return ref.watch(memoFilterProvider).sortOrder;
  }

  /// ルールを更新します
  void setSortOrder(MemoSortOrder sortOrder) {
    ref.read(memoFilterProvider.notifier).setSortOrder(sortOrder);
  }
}

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
