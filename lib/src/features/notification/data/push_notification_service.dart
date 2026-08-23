import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sample/src/features/notification/domain/notification_payload.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// 🔔 Push通知およびローカル通知の統合管理サービス
class PushNotificationService {
  /// コンストラクタ（DI & 多言語化対応・必須引数化）
  PushNotificationService({
    required Talker talker,
    required this.channelName,
    required this.channelDescription,
    required this.defaultTitle,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    this.onNotificationTap,
  }) : _messaging = messaging,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin(),
       _talker = talker;

  final FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Talker _talker;
  bool _isLocalNotificationsInitialized = false;

  /// 通知チャンネル名（多言語対応）
  final String channelName;

  /// 通知チャンネル説明（多言語対応）
  final String channelDescription;

  /// デフォルトの通知タイトル（多言語対応）
  final String defaultTitle;

  /// 通知タップ時に呼び出されるコールバック
  final void Function(NotificationPayload payload)? onNotificationTap;

  /// 高優先度通知チャンネルID
  static const String highImportanceChannelId = 'high_importance_channel';

  /// Android 用の通知チャンネル定義を作成
  AndroidNotificationChannel get highImportanceChannel =>
      AndroidNotificationChannel(
        highImportanceChannelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
      );

  /// 通知機能の初期化（チャンネル登録、リスナー設定）
  Future<void> initialize() async {
    // 1. Android 通知チャンネルの作成 & ローカル通知プラグインの初期化
    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(highImportanceChannel);

      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
      );

      final initialized = await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          _talker.info('🔔 ローカル通知がタップされました');
          if (response.payload != null) {
            try {
              final map = jsonDecode(response.payload!) as Map<String, dynamic>;
              final payload = NotificationPayload.fromMap(map);
              onNotificationTap?.call(payload);
            } on Object catch (e, st) {
              _talker.error('通知ペイロードのパースに失敗しました', e, st);
            }
          }
        },
      );
      _isLocalNotificationsInitialized = initialized ?? true;
    } on Object catch (e, st) {
      _isLocalNotificationsInitialized = false;
      _talker.warning('ローカル通知プラグインの初期化をスキップしました', e, st);
    }

    // 2. Firebase Messaging リスナーの設定（インスタンスが存在する場合）
    final messaging = _messaging;
    if (messaging != null) {
      if (_isLocalNotificationsInitialized) {
        // フォアグラウンドでの通知バナー表示オプション（iOS）
        // 自前で showLocalNotification によるバナー表示を行うため、二重表示を防ぐよう無効化（デフォルト: false）
        await messaging.setForegroundNotificationPresentationOptions();

        // フォアグラウンド受信リスナー（ローカル通知が初期化されている場合のみ自前バナーを表示）
        FirebaseMessaging.onMessage.listen(handleForegroundMessage);
      }

      // バックグラウンド通知タップリスナー（ローカル通知の成否にかかわらず登録）
      FirebaseMessaging.onMessageOpenedApp.listen(handleMessageOpenedApp);
    }
  }

  /// アプリ起動時（終了状態からの通知タップ起動）の初期通知ペイロードを取得
  Future<NotificationPayload?> getInitialNotification() async {
    // 1. Firebase Messaging からの起動通知をチェック
    final messaging = _messaging;
    if (messaging != null) {
      try {
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          _talker.info(
            '🔔 Firebase通知タップからのアプリ起動を検知: ${initialMessage.messageId}',
          );
          return NotificationPayload.fromMap(
            initialMessage.data,
            title: initialMessage.notification?.title,
            body: initialMessage.notification?.body,
          );
        }
      } on Object catch (e, st) {
        _talker.error('Firebase 初期通知の取得に失敗しました', e, st);
      }
    }

    // 2. ローカル通知プラグインからの起動通知をチェック
    try {
      final launchDetails = await _localNotifications
          .getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse != null) {
        final rawPayload = launchDetails.notificationResponse!.payload;
        if (rawPayload != null && rawPayload.isNotEmpty) {
          final json = jsonDecode(rawPayload) as Map<String, dynamic>;
          _talker.info('🔔 ローカル通知タップからのアプリ起動を検知');
          return NotificationPayload.fromJson(json);
        }
      }
    } on Object catch (e, st) {
      _talker.error('ローカル初期通知の取得に失敗しました', e, st);
    }

    return null;
  }

  /// 通知パーミッションの要求（Firebase Messaging & iOSローカル通知）
  Future<NotificationSettings?> requestPermission() async {
    try {
      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } on Object catch (e, st) {
      _talker.warning('iOSローカル通知権限リクエストをスキップしました', e, st);
    }

    final messaging = _messaging;
    if (messaging == null) return null;
    final settings = await messaging.requestPermission();
    _talker.info('🔔 通知権限ステータス: ${settings.authorizationStatus}');
    return settings;
  }

  /// 現在の通知権限ステータスを取得
  Future<NotificationSettings?> getNotificationSettings() async {
    final messaging = _messaging;
    if (messaging == null) return null;
    try {
      final settings = await messaging.getNotificationSettings();
      _talker.info('🔔 現在の通知権限ステータス: ${settings.authorizationStatus}');
      return settings;
    } on Object catch (e, st) {
      _talker.error('通知権限ステータスの取得に失敗しました', e, st);
      return null;
    }
  }

  /// FCM トークンの取得
  Future<String?> getToken() async {
    final messaging = _messaging;
    if (messaging == null) return null;
    try {
      final token = await messaging.getToken();
      _talker.info('🔔 FCM トークン取得成功');
      return token;
    } on Object catch (e, st) {
      _talker.error('FCM トークンの取得に失敗しました', e, st);
      return null;
    }
  }

  /// FCM トークン更新ストリーム
  Stream<String> get onTokenRefresh =>
      _messaging?.onTokenRefresh ?? const Stream.empty();

  int _generateNotificationId(RemoteMessage message) {
    if (message.messageId != null) {
      return message.messageId.hashCode.abs() % 2147483647;
    }
    return DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
  }

  /// フォアグラウンド受信時のメッセージ処理
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    _talker.info('🔔 フォアグラウンド通知を受信: ${message.messageId}');
    final payload = NotificationPayload.fromMap(
      message.data,
      title: message.notification?.title,
      body: message.notification?.body,
    );
    final notificationId = _generateNotificationId(message);
    await showLocalNotification(payload, id: notificationId);
  }

  /// バックグラウンド通知タップ時のメッセージ処理
  void handleMessageOpenedApp(RemoteMessage message) {
    _talker.info('🔔 バックグラウンド通知がタップされました: ${message.messageId}');
    final payload = NotificationPayload.fromMap(
      message.data,
      title: message.notification?.title,
      body: message.notification?.body,
    );
    onNotificationTap?.call(payload);
  }

  /// ローカル通知（バナー）の表示（テスト発火にも使用）
  Future<void> showLocalNotification(
    NotificationPayload payload, {
    int id = 0,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      highImportanceChannel.id,
      highImportanceChannel.name,
      channelDescription: highImportanceChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final payloadString = jsonEncode(payload.toJson());
    await _localNotifications.show(
      id: id,
      title: payload.title ?? defaultTitle,
      body: payload.body ?? '',
      notificationDetails: details,
      payload: payloadString,
    );
  }
}
