import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_filter_state.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_sort_order.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'memo_filter_notifier.g.dart';

/// メモの検索・絞り込み・ソート状態を一元管理する Notifier
@riverpod
class MemoFilterNotifier extends _$MemoFilterNotifier {
  @override
  MemoFilterState build() => const MemoFilterState();

  /// 検索クエリを更新します
  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  /// カテゴリをトグル（選択/解除）します
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
    state = state.copyWith(
      query: '',
      category: null,
      unsyncedOnly: false,
      resetCount: state.resetCount + 1,
    );
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
