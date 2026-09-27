import 'dart:async';

import 'package:flutter_sample/src/features/home_widget/application/home_widget_service.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_widget_sync_coordinator.g.dart';

/// メモ一覧のデータ変更をリアクティブに検知し、ホーム画面ウィジェットへ自動同期するコーディネーター
@Riverpod(keepAlive: true)
class HomeWidgetSyncCoordinator extends _$HomeWidgetSyncCoordinator {
  @override
  void build() {
    final service = ref.watch(homeWidgetServiceProvider);

    // 1. 初期化（App Group IDの設定）を実行
    unawaited(service.initialize());

    // 2. メモ一覧の状態（AsyncValue）を監視し、データが更新されたらウィジェットへ反映
    ref.listen(memoProvider, (previous, next) {
      if (next case AsyncData(value: final memos)) {
        unawaited(service.updateMemoWidget(memos: memos));
      }
    });
  }
}
