import 'dart:async';

import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/home_widget/application/home_widget_service.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_widget_sync_coordinator.g.dart';

/// メモ一覧のデータ変更をリアクティブに検知し、ホーム画面ウィジェットへ自動同期するコーディネーター
@Riverpod(keepAlive: true)
class HomeWidgetSyncCoordinator extends _$HomeWidgetSyncCoordinator {
  /// 非同期同期処理の競合防止・Fencingに使用する世代カウンター
  int _syncGeneration = 0;

  /// 二重初期化防止のための直近の認証状態キャッシュ
  String? _lastUserId;
  bool? _lastIsAuthenticated;

  @override
  void build() {
    final service = ref.watch(homeWidgetServiceProvider);

    // 1. 初期化（App Group IDの設定）を実行
    unawaited(service.initialize());

    // 現在の認証状態を記録
    _lastUserId = ref.read(currentUserIdProvider);
    _lastIsAuthenticated = ref.read(isAuthenticatedProvider);

    // 2. メモ一覧の状態（AsyncValue）を監視し、ログイン中であればウィジェットへ反映
    ref.listen(memoProvider, (previous, next) async {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      // 未ログイン状態では同期を停止（前ユーザーのメモ混入防止）
      if (!isAuthenticated) {
        return;
      }

      if (next case AsyncData(value: final memos)) {
        final currentGen = _syncGeneration;
        await service.updateMemoWidget(memos: memos);
        // 更新中にアカウント切替やログアウトが発生していた場合、
        // 古いメモが上書きされた可能性があるため、直ちに再初期化を実行（Fencing）
        if (currentGen != _syncGeneration) {
          unawaited(service.clearWidgetData());
        }
      }
    });

    // 3. 認証状態の変化（ログアウトや別アカウントへの切り替え）を監視し、
    //    進行中同期を遮断（Fencing）した上でウィジェット共有ストレージを初期化（空表示）する
    void handleAuthChange() {
      final nextUserId = ref.read(currentUserIdProvider);
      final nextAuth = ref.read(isAuthenticatedProvider);

      if (_lastUserId != nextUserId || _lastIsAuthenticated != nextAuth) {
        _lastUserId = nextUserId;
        _lastIsAuthenticated = nextAuth;
        _syncGeneration++;
        unawaited(service.clearWidgetData());
      }
    }

    ref
      ..listen<String?>(currentUserIdProvider, (_, _) => handleAuthChange())
      ..listen<bool>(isAuthenticatedProvider, (_, _) => handleAuthChange());
  }
}
