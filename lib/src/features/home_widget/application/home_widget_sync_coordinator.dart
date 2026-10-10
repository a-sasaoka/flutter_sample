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

  /// アカウント切り替え後に旧ユーザーのメモが再同期されるのを防ぐための同期停止フラグ
  bool _isSyncSuspended = false;

  /// 直近で同期を許可・確認したユーザーID
  String? _syncedUserId;

  /// ウィジェット共有ストレージへの書き込み順序を直列化（FIFO順）するためのチェーン
  Future<void> _writeQueue = Future<void>.value();

  /// ウィジェット書き込み処理を直列化キューに積む内部ヘルパー
  Future<void> _enqueueWrite(Future<void> Function() action) {
    final nextTask = _writeQueue
        .then((_) async {
          await action();
        })
        .catchError((Object _, StackTrace _) {
          // 直列化チェーンが例外で破断しないよう握りつぶす
        });
    _writeQueue = nextTask;
    return nextTask;
  }

  @override
  void build() {
    final service = ref.watch(homeWidgetServiceProvider);

    // 1. 初期化（App Group IDの設定）を実行
    unawaited(service.initialize());

    // 現在の認証状態を記録
    _lastUserId = ref.read(currentUserIdProvider);
    _lastIsAuthenticated = ref.read(isAuthenticatedProvider);

    // 未ログイン状態なら同期を停止、ログイン中であれば初期ユーザーとして同期を許可
    if (_lastIsAuthenticated != true) {
      _isSyncSuspended = true;
    } else {
      _syncedUserId = _lastUserId;
    }

    // 2. メモ一覧の状態（AsyncValue）を監視し、現在の認証ユーザーのメモと確認できている場合のみウィジェットへ反映
    ref.listen(memoProvider, (previous, next) {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final currentUserId = ref.read(currentUserIdProvider);

      // 未ログイン状態、またはアカウント切り替え後に現在のユーザーのメモ確認が未完了の場合は同期を停止（旧メモの混入防止）
      if (!isAuthenticated || _isSyncSuspended) {
        return;
      }

      // 同期許可されたユーザーIDと現在のユーザーIDが一致しない場合も同期を停止
      if (_syncedUserId != null && currentUserId != _syncedUserId) {
        return;
      }

      if (next case AsyncData(value: final memos)) {
        final taskGen = _syncGeneration;
        unawaited(
          _enqueueWrite(() async {
            // 実行順が回ってきた時点で世代が変わっている（ログアウトやアカウント切替）場合はスキップ
            if (taskGen != _syncGeneration) {
              return;
            }
            await service.updateMemoWidget(memos: memos);
          }),
        );
      }
    });

    // 3. 認証状態の変化（ログアウトや別アカウントへの切り替え）を監視し、
    //    直列化キュー経由でウィジェット共有ストレージを初期化（空表示）する
    void handleAuthChange() {
      final nextUserId = ref.read(currentUserIdProvider);
      final nextAuth = ref.read(isAuthenticatedProvider);

      if (_lastUserId != nextUserId || _lastIsAuthenticated != nextAuth) {
        // アカウント切り替え（旧ユーザーと異なるIDへの遷移）またはログアウト時は、
        // ローカルSQLiteに残存する旧メモの同期を停止する
        final isUserSwitched = _lastUserId != null && _lastUserId != nextUserId;
        final isSignedOut = !nextAuth || nextUserId == null;

        if (isUserSwitched || isSignedOut) {
          _isSyncSuspended = true;
          _syncedUserId = null;
        }

        _lastUserId = nextUserId;
        _lastIsAuthenticated = nextAuth;
        _syncGeneration++;
        unawaited(
          _enqueueWrite(() async {
            await service.clearWidgetData();
          }),
        );
      }
    }

    ref
      ..listen<String?>(currentUserIdProvider, (_, _) => handleAuthChange())
      ..listen<bool>(isAuthenticatedProvider, (_, _) => handleAuthChange());
  }

  /// 現在の認証ユーザーに属するメモであることが確認できた場合に、ウィジェット同期を再開・許可する
  void resumeSyncForCurrentUser() {
    final currentUserId = ref.read(currentUserIdProvider);
    final isAuthenticated = ref.read(isAuthenticatedProvider);

    if (isAuthenticated) {
      _isSyncSuspended = false;
      _syncedUserId = currentUserId;

      final memos = ref.read(memoProvider).value;
      if (memos != null) {
        final service = ref.read(homeWidgetServiceProvider);
        final taskGen = _syncGeneration;
        unawaited(
          _enqueueWrite(() async {
            if (taskGen != _syncGeneration) return;
            await service.updateMemoWidget(memos: memos);
          }),
        );
      }
    }
  }
}
