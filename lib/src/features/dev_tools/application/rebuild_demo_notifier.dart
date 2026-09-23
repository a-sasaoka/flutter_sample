import 'package:flutter_sample/src/features/dev_tools/domain/rebuild_demo_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rebuild_demo_notifier.g.dart';

/// 再ビルド検証デモの状態を管理するNotifier
@riverpod
class RebuildDemoNotifier extends _$RebuildDemoNotifier {
  @override
  RebuildDemoState build() {
    return RebuildDemoState.initial();
  }

  /// 最適化モード（Bad / Good）を切り替える
  void toggleOptimization() {
    state = state.copyWith(isOptimized: !state.isOptimized);
  }

  /// 検索クエリを更新する
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 状態を初期状態にリセットする
  void reset() {
    state = RebuildDemoState.initial();
  }
}
