import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_sort_order.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'memo_filter_state.freezed.dart';

/// 🔍 メモ一覧の検索・絞り込み・ソート条件を管理するモデル
@freezed
sealed class MemoFilterState with _$MemoFilterState {
  /// コンストラクタ
  const factory MemoFilterState({
    @Default('') String query,
    MemoCategory? category,
    @Default(false) bool unsyncedOnly,
    @Default(MemoSortOrder.createdAtDesc) MemoSortOrder sortOrder,
  }) = _MemoFilterState;

  const MemoFilterState._();

  /// 検索キーワードまたは絞り込み条件が適用されているかどうか
  bool get hasActiveFilter =>
      query.trim().isNotEmpty || category != null || unsyncedOnly;
}
