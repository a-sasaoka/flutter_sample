import 'dart:async';

import 'package:checks/checks.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sample/src/features/notification/data/firebase_messaging_background_handler.dart';
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

  bool throwOnInitialize = false;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    if (throwOnInitialize) {
      throw Exception('Local notification init failed');
    }
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

  final shownNotificationIds = <int>[];

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
    shownNotificationIds.add(id);
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

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/firebase_messaging'),
          (call) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(
            'plugins.flutter.io/firebase_messaging_background',
          ),
          (call) async => null,
        );
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
      () => mockAndroidPlugin.requestNotificationsPermission(),
    ).thenAnswer((_) async => true);

    when(
      () => mockMessaging.requestPermission(),
    ).thenAnswer((_) async => dummySettings);

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

    test(
      '初期化時にローカル通知の初期化が例外で失敗した場合、エラーログをhandleしフォアグラウンド表示設定をスキップすること',
      () async {
        fakeLocalNotifications.throwOnInitialize = true;

        await service.initialize();

        verify(
          () => mockTalker.handle(
            any<Object>(),
            any<StackTrace>(),
            any<String>(),
          ),
        ).called(1);

        // フォアグラウンド表示オプションが無効化（スキップ）されていること
        verifyNever(
          () => mockMessaging.setForegroundNotificationPresentationOptions(),
        );
      },
    );

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

    test('ローカル通知タップ時のJSONが不正な場合エラーログがhandleされること', () async {
      await service.initialize();

      const invalidResponse = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'invalid-json',
      );
      fakeLocalNotifications.onNotificationResponseCallback?.call(
        invalidResponse,
      );

      verify(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace>(),
          any<String>(),
        ),
      ).called(1);
    });

    test('firebaseMessagingBackgroundHandler が例外なく完了すること', () async {
      const message = RemoteMessage(
        messageId: 'bg_msg_123',
        data: {'key': 'value'},
      );
      await check(
        firebaseMessagingBackgroundHandler(message),
      ).completes();
    });

    test('requestPermission でAndroidおよびiOSプラグインの権限要求が実行されステータスを返すこと', () async {
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

      verify(
        () => mockIOSPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ),
      ).called(1);
      verify(
        () => mockAndroidPlugin.requestNotificationsPermission(),
      ).called(1);
    });

    test(
      'messaging が null かつローカル権限が許可された場合 authorized な settings を返すこと',
      () async {
        final serviceWithoutMessaging = PushNotificationService(
          localNotifications: fakeLocalNotifications,
          talker: mockTalker,
          channelName: 'Test Channel',
          channelDescription: 'Test Description',
          defaultTitle: 'Test Title',
        );

        final result = await serviceWithoutMessaging.requestPermission();
        check(result).isNotNull();
        check(
          result?.authorizationStatus,
        ).equals(AuthorizationStatus.authorized);
      },
    );

    test('messaging が null かつローカル権限が拒否された場合 denied な settings を返すこと', () async {
      when(
        () => mockIOSPlugin.requestPermissions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenAnswer((_) async => false);
      when(
        () => mockAndroidPlugin.requestNotificationsPermission(),
      ).thenAnswer((_) async => false);

      final serviceWithoutMessaging = PushNotificationService(
        localNotifications: fakeLocalNotifications,
        talker: mockTalker,
        channelName: 'Test Channel',
        channelDescription: 'Test Description',
        defaultTitle: 'Test Title',
      );

      final result = await serviceWithoutMessaging.requestPermission();
      check(result).isNotNull();
      check(result?.authorizationStatus).equals(AuthorizationStatus.denied);
    });

    test('messaging が null かつローカル権限結果が null の場合 null を返すこと', () async {
      when(
        () => mockIOSPlugin.requestPermissions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenAnswer((_) async => null);
      when(
        () => mockAndroidPlugin.requestNotificationsPermission(),
      ).thenAnswer((_) async => null);

      final serviceWithoutMessaging = PushNotificationService(
        localNotifications: fakeLocalNotifications,
        talker: mockTalker,
        channelName: 'Test Channel',
        channelDescription: 'Test Description',
        defaultTitle: 'Test Title',
      );

      final result = await serviceWithoutMessaging.requestPermission();
      check(result).isNull();
    });

    test('ローカル権限リクエスト時に例外が発生した場合エラーログをhandleすること', () async {
      when(
        () => mockIOSPlugin.requestPermissions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenThrow(Exception('Permission error'));

      final serviceWithoutMessaging = PushNotificationService(
        localNotifications: fakeLocalNotifications,
        talker: mockTalker,
        channelName: 'Test Channel',
        channelDescription: 'Test Description',
        defaultTitle: 'Test Title',
      );

      final result = await serviceWithoutMessaging.requestPermission();
      check(result).isNull();

      verify(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace>(),
          any<String>(),
        ),
      ).called(1);
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

    test('getNotificationSettings で例外発生時に null を返しエラーログをhandleすること', () async {
      when(
        () => mockMessaging.getNotificationSettings(),
      ).thenThrow(Exception('Settings error'));

      final settings = await service.getNotificationSettings();
      check(settings).isNull();
      verify(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace>(),
          any<String>(),
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

    test('getToken で例外発生時に null を返しエラーログをhandleすること', () async {
      when(() => mockMessaging.getToken()).thenThrow(Exception('FCM error'));

      final token = await service.getToken();
      check(token).isNull();
      verify(
        () => mockTalker.handle(
          any<Object>(),
          any<StackTrace>(),
          any<String>(),
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

    test(
      'handleForegroundMessage で一意な通知IDが生成され showLocalNotification が呼ばれること',
      () async {
        const message = RemoteMessage(
          messageId: 'fg_123',
          data: {'path': '/profile'},
          notification: RemoteNotification(
            title: 'Foreground Title',
            body: 'Foreground Body',
          ),
        );

        await service.handleForegroundMessage(message);

        final expectedId = 'fg_123'.hashCode.abs() % 2147483647;
        check(fakeLocalNotifications.showCallCount).equals(1);
        check(fakeLocalNotifications.lastShowId).equals(expectedId);
        check(fakeLocalNotifications.lastShowTitle).equals('Foreground Title');
        check(fakeLocalNotifications.lastShowBody).equals('Foreground Body');
      },
    );

    test('messageId が null の場合でも通知IDが生成されて表示されること', () async {
      const message = RemoteMessage(
        data: {'path': '/profile'},
        notification: RemoteNotification(
          title: 'No MessageId Title',
          body: 'No MessageId Body',
        ),
      );

      await service.handleForegroundMessage(message);

      check(fakeLocalNotifications.showCallCount).equals(1);
      check(fakeLocalNotifications.lastShowId).isNotNull();
      check(fakeLocalNotifications.lastShowTitle).equals('No MessageId Title');
    });

    test('連続して複数のフォアグラウンド通知を受信した際に異なる通知IDで表示されること', () async {
      const message1 = RemoteMessage(
        messageId: 'msg_1',
        data: {'path': '/chat/1'},
        notification: RemoteNotification(title: 'Msg 1'),
      );
      const message2 = RemoteMessage(
        messageId: 'msg_2',
        data: {'path': '/chat/2'},
        notification: RemoteNotification(title: 'Msg 2'),
      );

      await service.handleForegroundMessage(message1);
      await service.handleForegroundMessage(message2);

      check(fakeLocalNotifications.showCallCount).equals(2);
      check(fakeLocalNotifications.shownNotificationIds.length).equals(2);
      final id1 = fakeLocalNotifications.shownNotificationIds[0];
      final id2 = fakeLocalNotifications.shownNotificationIds[1];
      check(id1 != id2).isTrue();
    });

    test(
      'messageId が null の通知を連続受信した際に異なる通知IDで表示されること',
      () async {
        const nullMsg1 = RemoteMessage(
          data: {'path': '/item/1'},
          notification: RemoteNotification(title: 'Null Msg 1'),
        );
        const nullMsg2 = RemoteMessage(
          data: {'path': '/item/2'},
          notification: RemoteNotification(title: 'Null Msg 2'),
        );

        await service.handleForegroundMessage(nullMsg1);
        await service.handleForegroundMessage(nullMsg2);

        check(fakeLocalNotifications.showCallCount).equals(2);
        check(fakeLocalNotifications.shownNotificationIds.length).equals(2);
        final id1 = fakeLocalNotifications.shownNotificationIds[0];
        final id2 = fakeLocalNotifications.shownNotificationIds[1];
        check(id1 != id2).isTrue();
      },
    );

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
