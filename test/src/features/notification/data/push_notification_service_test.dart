import 'dart:async';

import 'package:checks/checks.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sample/src/features/notification/data/push_notification_service.dart';
import 'package:flutter_sample/src/features/notification/domain/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class MockIOSFlutterLocalNotificationsPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

class MockTalker extends Mock implements Talker {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

class FakeFlutterLocalNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  bool initializeCalled = false;
  DidReceiveNotificationResponseCallback? onNotificationResponseCallback;
  AndroidFlutterLocalNotificationsPlugin? androidImplementation;
  IOSFlutterLocalNotificationsPlugin? iosImplementation;
  int showCallCount = 0;
  int? lastShowId;
  String? lastShowTitle;
  String? lastShowBody;
  String? lastShowPayload;

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() {
    if (T == AndroidFlutterLocalNotificationsPlugin) {
      return androidImplementation as T?;
    }
    if (T == IOSFlutterLocalNotificationsPlugin) {
      return iosImplementation as T?;
    }
    return null;
  }

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCalled = true;
    onNotificationResponseCallback = onDidReceiveNotificationResponse;
    return true;
  }

  NotificationAppLaunchDetails? launchDetails;
  bool throwOnGetLaunchDetails = false;

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async {
    if (throwOnGetLaunchDetails) {
      throw Exception('Launch details error');
    }
    return launchDetails;
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    showCallCount++;
    lastShowId = id;
    lastShowTitle = title;
    lastShowBody = body;
    lastShowPayload = payload;
  }
}

class FakeAndroidNotificationChannel extends Fake
    implements AndroidNotificationChannel {}

void main() {
  late MockFirebaseMessaging mockMessaging;
  late FakeFlutterLocalNotificationsPlugin fakeLocalNotifications;
  late MockAndroidFlutterLocalNotificationsPlugin mockAndroidPlugin;
  late MockIOSFlutterLocalNotificationsPlugin mockIOSPlugin;
  late MockTalker mockTalker;
  late PushNotificationService service;

  setUpAll(() {
    registerFallbackValue(FakeAndroidNotificationChannel());
    registerFallbackValue(StackTrace.current);
    registerFallbackValue(Exception('fallback'));
  });

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    mockAndroidPlugin = MockAndroidFlutterLocalNotificationsPlugin();
    mockIOSPlugin = MockIOSFlutterLocalNotificationsPlugin();
    mockTalker = MockTalker();
    fakeLocalNotifications = FakeFlutterLocalNotificationsPlugin()
      ..androidImplementation = mockAndroidPlugin
      ..iosImplementation = mockIOSPlugin;

    when(
      () => mockAndroidPlugin.createNotificationChannel(any()),
    ).thenAnswer((_) async {});

    when(
      () => mockIOSPlugin.requestPermissions(
        alert: any(named: 'alert'),
        badge: any(named: 'badge'),
        sound: any(named: 'sound'),
      ),
    ).thenAnswer((_) async => true);

    when(
      () => mockMessaging.setForegroundNotificationPresentationOptions(
        alert: any(named: 'alert'),
        badge: any(named: 'badge'),
        sound: any(named: 'sound'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockMessaging.getInitialMessage()).thenAnswer((_) async => null);
    when(
      () => mockMessaging.getToken(),
    ).thenAnswer((_) async => 'sample_fcm_token');
    when(
      () => mockMessaging.onTokenRefresh,
    ).thenAnswer((_) => const Stream.empty());

    service = PushNotificationService(
      messaging: mockMessaging,
      localNotifications: fakeLocalNotifications,
      talker: mockTalker,
      channelName: 'Test Channel',
      channelDescription: 'Test Description',
      defaultTitle: 'Test Title',
    );
  });

  group('PushNotificationService', () {
    test('初期化時にAndroidチャンネル登録とプラグイン初期化が実行されること', () async {
      await service.initialize();

      verify(
        () => mockAndroidPlugin.createNotificationChannel(any()),
      ).called(1);

      verify(
        () => mockMessaging.setForegroundNotificationPresentationOptions(),
      ).called(1);

      check(fakeLocalNotifications.initializeCalled).isTrue();
    });

    test('getInitialNotification でFirebaseの初期通知が取得できること', () async {
      const message = RemoteMessage(
        messageId: 'initial_123',
        data: {'path': '/memos'},
        notification: RemoteNotification(
          title: 'Initial Title',
          body: 'Initial Body',
        ),
      );

      when(
        () => mockMessaging.getInitialMessage(),
      ).thenAnswer((_) async => message);

      final payload = await service.getInitialNotification();

      check(payload).isNotNull();
      check(payload?.path).equals('/memos');
      check(payload?.title).equals('Initial Title');
      check(payload?.body).equals('Initial Body');
    });

    test('getInitialNotification でローカル通知の起動情報が取得できること', () async {
      fakeLocalNotifications.launchDetails = const NotificationAppLaunchDetails(
        true,
        notificationResponse: NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          payload: '{"path":"/chat","title":"Chat","body":"Hello"}',
        ),
      );

      final payload = await service.getInitialNotification();

      check(payload).isNotNull();
      check(payload?.path).equals('/chat');
      check(payload?.title).equals('Chat');
      check(payload?.body).equals('Hello');
    });

    test('getInitialNotification で初期通知がない場合 null を返すこと', () async {
      final payload = await service.getInitialNotification();
      check(payload).isNull();
    });

    test('getInitialNotification で例外発生時に安全に null を返すこと', () async {
      when(
        () => mockMessaging.getInitialMessage(),
      ).thenThrow(Exception('Firebase error'));
      fakeLocalNotifications.throwOnGetLaunchDetails = true;

      final payload = await service.getInitialNotification();
      check(payload).isNull();
    });

    test('ローカル通知タップ時に onNotificationTap が呼ばれること', () async {
      NotificationPayload? tappedPayload;
      final serviceWithCallback = PushNotificationService(
        messaging: mockMessaging,
        localNotifications: fakeLocalNotifications,
        talker: mockTalker,
        channelName: 'Test Channel',
        channelDescription: 'Test Description',
        defaultTitle: 'Test Title',
        onNotificationTap: (payload) {
          tappedPayload = payload;
        },
      );

      await serviceWithCallback.initialize();

      // コールバックを発火
      const response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '{"path":"/chat","title":"Hello"}',
      );
      fakeLocalNotifications.onNotificationResponseCallback?.call(response);

      check(tappedPayload).isNotNull();
      check(tappedPayload?.path).equals('/chat');
      check(tappedPayload?.title).equals('Hello');
    });

    test('ローカル通知タップ時のJSONが不正な場合エラーログが出力されること', () async {
      await service.initialize();

      const invalidResponse = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'invalid-json',
      );
      fakeLocalNotifications.onNotificationResponseCallback?.call(
        invalidResponse,
      );

      verify(
        () => mockTalker.error(
          any<String>(),
          any<Object>(),
          any<StackTrace>(),
        ),
      ).called(1);
    });

    test('requestPermission が正常に NotificationSettings を返すこと', () async {
      final mockSettings = MockNotificationSettings();
      when(
        () => mockSettings.authorizationStatus,
      ).thenReturn(AuthorizationStatus.authorized);
      when(
        () => mockMessaging.requestPermission(),
      ).thenAnswer((_) async => mockSettings);

      final result = await service.requestPermission();
      check(result).isNotNull();
      check(result?.authorizationStatus).equals(AuthorizationStatus.authorized);
    });

    test('messaging が null の場合 requestPermission は null を返すこと', () async {
      final serviceWithoutMessaging = PushNotificationService(
        talker: mockTalker,
        channelName: 'Test Channel',
        channelDescription: 'Test Description',
        defaultTitle: 'Test Title',
      );

      final result = await serviceWithoutMessaging.requestPermission();
      check(result).isNull();
    });

    test('getNotificationSettings が正常にステータスを返すこと', () async {
      const dummySettings = NotificationSettings(
        alert: AppleNotificationSetting.enabled,
        announcement: AppleNotificationSetting.notSupported,
        authorizationStatus: AuthorizationStatus.authorized,
        badge: AppleNotificationSetting.enabled,
        carPlay: AppleNotificationSetting.notSupported,
        criticalAlert: AppleNotificationSetting.notSupported,
        lockScreen: AppleNotificationSetting.enabled,
        notificationCenter: AppleNotificationSetting.enabled,
        showPreviews: AppleShowPreviewSetting.always,
        timeSensitive: AppleNotificationSetting.notSupported,
        sound: AppleNotificationSetting.enabled,
        providesAppNotificationSettings: AppleNotificationSetting.notSupported,
      );
      when(
        () => mockMessaging.getNotificationSettings(),
      ).thenAnswer((_) async => dummySettings);

      final settings = await service.getNotificationSettings();
      check(settings).isNotNull();
      check(
        settings?.authorizationStatus,
      ).equals(AuthorizationStatus.authorized);
    });

    test('getNotificationSettings で例外発生時に null を返しエラーログを出力すること', () async {
      when(
        () => mockMessaging.getNotificationSettings(),
      ).thenThrow(Exception('Settings error'));

      final settings = await service.getNotificationSettings();
      check(settings).isNull();
      verify(
        () => mockTalker.error(
          any<String>(),
          any<Object>(),
          any<StackTrace>(),
        ),
      ).called(1);
    });

    test('messaging が null の場合 getNotificationSettings は null を返すこと', () async {
      final serviceWithoutMessaging = PushNotificationService(
        talker: mockTalker,
        channelName: 'Test Channel',
        channelDescription: 'Test Description',
        defaultTitle: 'Test Title',
      );

      final settings = await serviceWithoutMessaging.getNotificationSettings();
      check(settings).isNull();
    });

    test('getToken が正常に FCM トークンを返すこと', () async {
      when(
        () => mockMessaging.getToken(),
      ).thenAnswer((_) async => 'sample_fcm_token');

      final token = await service.getToken();
      check(token).equals('sample_fcm_token');
    });

    test('getToken で例外発生時に null を返しエラーログを出力すること', () async {
      when(() => mockMessaging.getToken()).thenThrow(Exception('FCM error'));

      final token = await service.getToken();
      check(token).isNull();
      verify(
        () => mockTalker.error(
          any<String>(),
          any<Object>(),
          any<StackTrace>(),
        ),
      ).called(1);
    });

    test('messaging が null の場合 getToken は null を返すこと', () async {
      final serviceWithoutMessaging = PushNotificationService(
        talker: mockTalker,
        channelName: 'Test Channel',
        channelDescription: 'Test Description',
        defaultTitle: 'Test Title',
      );

      final token = await serviceWithoutMessaging.getToken();
      check(token).isNull();
    });

    test('onTokenRefresh ストリームが購読できること', () async {
      final controller = StreamController<String>();
      when(
        () => mockMessaging.onTokenRefresh,
      ).thenAnswer((_) => controller.stream);

      final stream = service.onTokenRefresh;
      final tokens = <String>[];
      final subscription = stream.listen(tokens.add);

      controller.add('token_1');
      await Future<void>.delayed(Duration.zero);

      check(tokens).deepEquals(['token_1']);
      await subscription.cancel();
      await controller.close();
    });

    test('messaging が null の場合 onTokenRefresh は空ストリームを返すこと', () {
      final serviceWithoutMessaging = PushNotificationService(
        talker: mockTalker,
        channelName: 'Test Channel',
        channelDescription: 'Test Description',
        defaultTitle: 'Test Title',
      );

      check(serviceWithoutMessaging.onTokenRefresh).isA<Stream<String>>();
    });

    test('showLocalNotification でローカル通知が表示されること', () async {
      const payload = NotificationPayload(
        path: '/chat',
        title: 'Chat Message',
        body: 'You got a new message',
      );

      await service.showLocalNotification(payload);

      check(fakeLocalNotifications.showCallCount).equals(1);
      check(fakeLocalNotifications.lastShowId).equals(0);
      check(fakeLocalNotifications.lastShowTitle).equals('Chat Message');
      check(fakeLocalNotifications.lastShowBody).equals(
        'You got a new message',
      );
      check(
        fakeLocalNotifications.lastShowPayload,
      ).isNotNull().contains('"/chat"');
    });

    test('handleForegroundMessage で showLocalNotification が呼ばれること', () async {
      const message = RemoteMessage(
        messageId: 'fg_123',
        data: {'path': '/profile'},
        notification: RemoteNotification(
          title: 'Foreground Title',
          body: 'Foreground Body',
        ),
      );

      await service.handleForegroundMessage(message);

      check(fakeLocalNotifications.showCallCount).equals(1);
      check(fakeLocalNotifications.lastShowId).equals(0);
      check(fakeLocalNotifications.lastShowTitle).equals('Foreground Title');
      check(fakeLocalNotifications.lastShowBody).equals('Foreground Body');
    });

    test('handleMessageOpenedApp で onNotificationTap が呼ばれること', () {
      NotificationPayload? tappedPayload;
      final serviceWithCallback = PushNotificationService(
        messaging: mockMessaging,
        localNotifications: fakeLocalNotifications,
        talker: mockTalker,
        channelName: 'Test Channel',
        channelDescription: 'Test Description',
        defaultTitle: 'Test Title',
        onNotificationTap: (payload) {
          tappedPayload = payload;
        },
      );

      const message = RemoteMessage(
        messageId: 'bg_123',
        data: {'path': '/chat'},
        notification: RemoteNotification(
          title: 'BG Title',
          body: 'BG Body',
        ),
      );

      serviceWithCallback.handleMessageOpenedApp(message);

      check(tappedPayload).isNotNull();
      check(tappedPayload?.path).equals('/chat');
      check(tappedPayload?.title).equals('BG Title');
      check(tappedPayload?.body).equals('BG Body');
    });
  });
}
