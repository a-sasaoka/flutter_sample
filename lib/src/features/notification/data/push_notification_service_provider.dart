import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/notification/application/notification_notifier.dart';
import 'package:flutter_sample/src/features/notification/data/push_notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_notification_service_provider.g.dart';

/// 🔔 [PushNotificationService] を提供するプロバイダー
@Riverpod(keepAlive: true)
PushNotificationService pushNotificationService(Ref ref) {
  final talker = ref.watch(loggerProvider);

  // 1. 現在の言語設定（未設定の場合は端末のロケール）を取得
  final currentLocale =
      ref.watch(localeProvider).value ?? PlatformDispatcher.instance.locale;
  final l10n = lookupAppLocalizations(currentLocale);

  // 2. Firebase 初期化状態を安全に判定
  // coverage:ignore-start
  final messaging = Firebase.apps.isNotEmpty
      ? FirebaseMessaging.instance
      : null;
  // coverage:ignore-end

  // 3. 多言語化されたテキストと通知タップハンドラを注入してサービスを生成
  return PushNotificationService(
    talker: talker,
    messaging: messaging,
    localNotifications: FlutterLocalNotificationsPlugin(),
    channelName: l10n.notificationChannelHighImportanceName,
    channelDescription: l10n.notificationChannelHighImportanceDescription,
    defaultTitle: l10n.notificationDefaultTitle,
    onNotificationTap: (payload) {
      ref.read(notificationProvider.notifier).handleNotificationTap(payload);
    },
  );
}
