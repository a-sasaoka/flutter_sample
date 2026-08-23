import 'dart:async';

import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/features/notification/application/notification_state.dart';
import 'package:flutter_sample/src/features/notification/data/push_notification_service_provider.dart';
import 'package:flutter_sample/src/features/notification/domain/notification_payload.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_notifier.g.dart';

/// 🔔 通知の状態とアクションを管理する Notifier
@Riverpod(keepAlive: true)
class NotificationNotifier extends _$NotificationNotifier {
  @override
  NotificationState build() {
    unawaited(_init());
    return const NotificationState.loading();
  }

  Future<void> _init() async {
    final service = ref.read(pushNotificationServiceProvider);

    await service.initialize();

    final token = await service.getToken();
    final settings = await service.getNotificationSettings();

    if (!ref.mounted) return;

    state = NotificationState.data(
      fcmToken: token,
      authorizationStatus: settings?.authorizationStatus,
    );

    service.onTokenRefresh.listen((newToken) {
      if (!ref.mounted) return;
      if (state case final NotificationStateData dataState) {
        state = dataState.copyWith(fcmToken: newToken);
      }
    });
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
      state = dataState.copyWith(latestPayload: payload);
    }
    if (payload.isNavigable && payload.path != null) {
      ref.read(routerProvider).go(payload.path!);
    }
  }
}
