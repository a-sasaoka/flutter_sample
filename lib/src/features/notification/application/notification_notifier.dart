import 'dart:async';

import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/notification/application/notification_state.dart';
import 'package:flutter_sample/src/features/notification/data/push_notification_service_provider.dart';
import 'package:flutter_sample/src/features/notification/domain/notification_payload.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_notifier.g.dart';

/// 🔔 通知の状態とアクションを管理する Notifier
@Riverpod(keepAlive: true)
class NotificationNotifier extends _$NotificationNotifier {
  NotificationPayload? _pendingPayload;
  bool _isCleaningUp = false;
  bool _isServiceInitialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _latestRefreshedToken;

  @override
  NotificationState build() {
    ref.onDispose(() {
      unawaited(_tokenRefreshSubscription?.cancel());
    });

    // 認証状態の変化（ログアウトや別アカウントへの切り替え）を監視し、
    // FCMトークンの破棄、通知バナーの消去、および再ログイン時のトークン再取得を行う
    ref
      ..listen<String?>(currentUserIdProvider, (previous, next) {
        if (previous != next) {
          unawaited(_handleUserChanged(previous, next));
        }
      })
      ..listen<bool>(isAuthenticatedProvider, (previous, next) {
        if (previous != next) {
          if (!next) {
            unawaited(_handleSignOut());
          } else if (ref.read(currentUserIdProvider) == null) {
            // 自前認証ログイン（currentUserIdProvider は null だが
            // isAuthenticated が true に遷移）
            unawaited(_init());
          }
        }
      });

    unawaited(_init());
    return const NotificationState.loading();
  }

  Future<void> _init() async {
    final talker = ref.read(loggerProvider);
    try {
      final service = ref.read(pushNotificationServiceProvider);

      // 通知サービス自体の初期化（チャンネル作成・受信リスナー設定）は初回のみ実行
      if (!_isServiceInitialized) {
        await service.initialize();
        _isServiceInitialized = true;
      }

      // トークン更新ストリームの購読（初回のみ登録して再利用）
      _tokenRefreshSubscription ??= service.onTokenRefresh.listen((newToken) {
        _latestRefreshedToken = newToken;
        if (!ref.mounted) return;
        if (state case final NotificationStateData dataState) {
          state = dataState.copyWith(fcmToken: newToken);
        }
      });

      final token = await service.getToken();
      final settings = await service.getNotificationSettings();
      final initialPayload = await service.getInitialNotification();

      if (!ref.mounted) return;

      final pending = _pendingPayload;
      _pendingPayload = null;

      final refreshedToken = _latestRefreshedToken;
      _latestRefreshedToken = null;

      state = NotificationState.data(
        fcmToken: refreshedToken ?? token,
        authorizationStatus: settings?.authorizationStatus,
        initialPayload: initialPayload,
        latestPayload: pending,
        lastReceivedPayload: pending ?? initialPayload,
      );
    } on Object catch (e, st) {
      if (!ref.mounted) return;
      talker.handle(e, st, '通知の初期化処理中にエラーが発生しました');
      state = NotificationState.error(message: e.toString());
    }
  }

  /// サインアウト時のクリーンアップ処理（トークン破棄・通知バナー消去・状態リセット）
  Future<void> _handleSignOut() async {
    if (_isCleaningUp) return;
    _isCleaningUp = true;
    try {
      final service = ref.read(pushNotificationServiceProvider);
      await service.deleteToken();
      if (!ref.mounted) return;
      await service.cancelAllNotifications();
      if (!ref.mounted) return;

      _pendingPayload = null;
      if (state case final NotificationStateData dataState) {
        state = dataState.copyWith(
          fcmToken: null,
          initialPayload: null,
          latestPayload: null,
          lastReceivedPayload: null,
        );
      }
    } finally {
      _isCleaningUp = false;
    }
  }

  /// ユーザーID変更時の処理（アカウント切り替え時は破棄後に新トークン再取得）
  Future<void> _handleUserChanged(String? previous, String? next) async {
    if (next == null) {
      await _handleSignOut();
      return;
    }

    if (previous != null && previous != next) {
      // 別アカウントへの切り替え
      final service = ref.read(pushNotificationServiceProvider);
      await service.deleteToken();
      if (!ref.mounted) return;
      await service.cancelAllNotifications();
      if (!ref.mounted) return;

      _pendingPayload = null;
      if (state case final NotificationStateData dataState) {
        state = dataState.copyWith(
          fcmToken: null,
          initialPayload: null,
          latestPayload: null,
          lastReceivedPayload: null,
        );
      }
      await _init();
    } else if (previous == null) {
      // ログイン時: トークン再取得・初期化
      await _init();
    }
  }

  /// 初期起動時の通知ペイロードを取り出し、二重遷移を防ぐために消費（クリア）する
  NotificationPayload? consumeInitialPayload() {
    if (state case final NotificationStateData dataState) {
      final payload = dataState.initialPayload;
      if (payload != null) {
        state = dataState.copyWith(initialPayload: null);
        return payload;
      }
    }
    return null;
  }

  /// 最新のタップ通知ペイロードを取り出し、二重遷移を防ぐために消費（クリア）する
  NotificationPayload? consumeLatestPayload() {
    if (state case final NotificationStateData dataState) {
      final payload = dataState.latestPayload;
      if (payload != null) {
        state = dataState.copyWith(latestPayload: null);
        return payload;
      }
    }
    return null;
  }

  /// 通知パーミッションを要求
  Future<void> requestPermission() async {
    final service = ref.read(pushNotificationServiceProvider);
    final settings = await service.requestPermission();
    if (settings != null) {
      if (state case final NotificationStateData dataState) {
        state = dataState.copyWith(
          authorizationStatus: settings.authorizationStatus,
        );
      }
    }
  }

  /// テスト通知をローカル発火
  Future<void> sendTestNotification(NotificationPayload payload) async {
    final service = ref.read(pushNotificationServiceProvider);
    await service.showLocalNotification(payload);
  }

  /// 通知タップ時のディープリンク画面遷移ハンドラ
  void handleNotificationTap(NotificationPayload payload) {
    if (state case final NotificationStateData dataState) {
      state = dataState.copyWith(
        latestPayload: payload,
        lastReceivedPayload: payload,
      );
    } else {
      _pendingPayload = payload;
    }
  }
}
