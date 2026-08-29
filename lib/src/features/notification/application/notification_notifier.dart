import 'dart:async';

import 'package:flutter_sample/src/features/notification/application/notification_state.dart';
import 'package:flutter_sample/src/features/notification/data/push_notification_service_provider.dart';
import 'package:flutter_sample/src/features/notification/domain/notification_payload.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_notifier.g.dart';

/// 🔔 通知の状態とアクションを管理する Notifier
@Riverpod(keepAlive: true)
class NotificationNotifier extends _$NotificationNotifier {
  NotificationPayload? _pendingPayload;

  @override
  NotificationState build() {
    unawaited(_init());
    return const NotificationState.loading();
  }

  Future<void> _init() async {
    try {
      final service = ref.read(pushNotificationServiceProvider);

      await service.initialize();

      String? refreshedToken;
      final subscription = service.onTokenRefresh.listen((newToken) {
        refreshedToken = newToken;
        if (!ref.mounted) return;
        if (state case final NotificationStateData dataState) {
          state = dataState.copyWith(fcmToken: newToken);
        }
      });
      ref.onDispose(subscription.cancel);

      final token = await service.getToken();
      final settings = await service.getNotificationSettings();
      final initialPayload = await service.getInitialNotification();

      if (!ref.mounted) return;

      final pending = _pendingPayload;
      _pendingPayload = null;

      state = NotificationState.data(
        fcmToken: refreshedToken ?? token,
        authorizationStatus: settings?.authorizationStatus,
        initialPayload: initialPayload,
        latestPayload: pending,
        lastReceivedPayload: pending ?? initialPayload,
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      state = NotificationState.error(message: e.toString());
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
