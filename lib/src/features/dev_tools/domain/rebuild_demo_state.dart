import 'package:flutter_sample/src/features/dev_tools/domain/rebuild_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'rebuild_demo_state.freezed.dart';

/// 再ビルド検証デモ画面の状態クラス
@freezed
sealed class RebuildDemoState with _$RebuildDemoState {
  /// コンストラクタ
  const factory RebuildDemoState({
    required bool isOptimized,
    required String searchQuery,
    required List<RebuildItem> items,
  }) = _RebuildDemoState;

  const RebuildDemoState._();

  /// 初期状態
  factory RebuildDemoState.initial() => const RebuildDemoState(
    isOptimized: false,
    searchQuery: '',
    items: defaultRebuildItems,
  );

  /// 検索クエリで絞り込まれたアイテム一覧
  List<RebuildItem> get filteredItems {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return items;
    }
    return items
        .where(
          (item) =>
              item.name.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query),
        )
        .toList();
  }
}
