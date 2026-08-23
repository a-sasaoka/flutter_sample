import 'dart:async';

import 'package:checks/checks.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/features/notification/application/notification_notifier.dart';
import 'package:flutter_sample/src/features/notification/application/notification_state.dart';
import 'package:flutter_sample/src/features/notification/data/push_notification_service.dart';
import 'package:flutter_sample/src/features/notification/data/push_notification_service_provider.dart';
import 'package:flutter_sample/src/features/notification/domain/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

class MockGoRouter extends Mock implements GoRouter {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

void main() {
  late MockPushNotificationService mockService;
  late MockGoRouter mockRouter;
  late StreamController<String> tokenRefreshController;

  setUpAll(() {
    registerFallbackValue(const NotificationPayload());
  });

  setUp(() {
    mockService = MockPushNotificationService();
    mockRouter = MockGoRouter();
    tokenRefreshController = StreamController<String>.broadcast();

    when(
      () => mockService.initialize(),
    ).thenAnswer((_) async {});
    when(
      () => mockService.getToken(),
    ).thenAnswer((_) async => 'initial_test_token');
    when(
      () => mockService.getNotificationSettings(),
    ).thenAnswer((_) async => null);
    when(
      () => mockService.getInitialNotification(),
    ).thenAnswer((_) async => null);
    when(
      () => mockService.onTokenRefresh,
    ).thenAnswer((_) => tokenRefreshController.stream);
  });

  tearDown(() async {
    await tokenRefreshController.close();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        pushNotificationServiceProvider.overrideWithValue(mockService),
        routerProvider.overrideWithValue(mockRouter),
      ],
    )..listen(notificationProvider, (previous, next) {});
    addTearDown(container.dispose);
    return container;
  }

  group('NotificationNotifier', () {
    test('初期化時にFCMトークンおよび権限ステータスを取得しNotificationState.dataに遷移すること', () async {
      when(() => mockService.getNotificationSettings()).thenAnswer(
        (_) async => const NotificationSettings(
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
          providesAppNotificationSettings:
              AppleNotificationSetting.notSupported,
        ),
      );

      final container = createContainer();

      // 初期状態は loading
      final initialState = container.read(notificationProvider);
      check(initialState).isA<NotificationStateLoading>();

      // 非同期初期化の完了を待機
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(notificationProvider);
      check(state).isA<NotificationStateData>();
      if (state case final NotificationStateData dataState) {
        check(dataState.fcmToken).equals('initial_test_token');
        check(
          dataState.authorizationStatus,
        ).equals(AuthorizationStatus.authorized);
      }
    });

    test('初期化時に例外が発生した場合 NotificationState.error に遷移すること', () async {
      when(
        () => mockService.initialize(),
      ).thenAnswer((_) async => throw Exception('Init failed'));

      final container = createContainer()..read(notificationProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(notificationProvider);
      check(state).isA<NotificationStateError>();
      if (state case final NotificationStateError errorState) {
        check(errorState.message).contains('Init failed');
      }
    });

    test('初期化中にコンテナが破棄された場合、状態更新が行われないこと', () async {
      final completer = Completer<void>();
      when(() => mockService.initialize()).thenAnswer((_) => completer.future);

      ProviderContainer(
          overrides: [
            pushNotificationServiceProvider.overrideWithValue(mockService),
            routerProvider.overrideWithValue(mockRouter),
          ],
        )
        ..listen(notificationProvider, (_, _) {})
        // 初期化処理の途中でコンテナを破棄
        ..dispose();

      completer.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });

    test(
      '初期通知が存在する場合 initialPayload に保持され consumeInitialPayload で消費できること',
      () async {
        const initialPayload = NotificationPayload(
          path: '/chat',
          title: 'Initial Chat',
          body: 'Hello',
        );
        when(
          () => mockService.getInitialNotification(),
        ).thenAnswer((_) async => initialPayload);

        final container = createContainer();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = container.read(notificationProvider);
        if (state case final NotificationStateData dataState) {
          check(dataState.initialPayload).equals(initialPayload);
        }

        final notifier = container.read(notificationProvider.notifier);
        final consumed = notifier.consumeInitialPayload();
        check(consumed).equals(initialPayload);

        final nextState = container.read(notificationProvider);
        if (nextState case final NotificationStateData dataState) {
          check(dataState.initialPayload).isNull();
        }

        // 2回目の消費は null
        check(notifier.consumeInitialPayload()).isNull();
      },
    );

    test('onTokenRefresh で新しいトークンが反映されること', () async {
      final container = createContainer();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      tokenRefreshController.add('updated_token_123');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(notificationProvider);
      if (state case final NotificationStateData dataState) {
        check(dataState.fcmToken).equals('updated_token_123');
      }
    });

    test('container が dispose された後の onTokenRefresh は無視されること', () async {
      final container = ProviderContainer(
        overrides: [
          pushNotificationServiceProvider.overrideWithValue(mockService),
          routerProvider.overrideWithValue(mockRouter),
        ],
      )..listen(notificationProvider, (previous, next) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));

      container.dispose();
      tokenRefreshController.add('ignore_token');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });

    test('requestPermission でステータスが更新されること', () async {
      final container = createContainer();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final mockSettings = MockNotificationSettings();
      when(
        () => mockSettings.authorizationStatus,
      ).thenReturn(AuthorizationStatus.authorized);
      when(
        () => mockService.requestPermission(),
      ).thenAnswer((_) async => mockSettings);

      final notifier = container.read(notificationProvider.notifier);
      await notifier.requestPermission();

      final state = container.read(notificationProvider);
      if (state case final NotificationStateData dataState) {
        check(
          dataState.authorizationStatus,
        ).equals(AuthorizationStatus.authorized);
      }
    });

    test('requestPermission で settings が null の場合ステータスは変化しないこと', () async {
      final container = createContainer();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      when(() => mockService.requestPermission()).thenAnswer((_) async => null);

      await container.read(notificationProvider.notifier).requestPermission();

      final state = container.read(notificationProvider);
      if (state case final NotificationStateData dataState) {
        check(dataState.authorizationStatus).isNull();
      }
    });

    test('sendTestNotification でサービスの showLocalNotification が呼ばれること', () async {
      final container = createContainer();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      when(
        () => mockService.showLocalNotification(any()),
      ).thenAnswer((_) async {});

      const payload = NotificationPayload(
        path: '/chat',
        title: 'Test',
        body: 'Body',
      );

      final notifier = container.read(notificationProvider.notifier);
      await notifier.sendTestNotification(payload);

      verify(() => mockService.showLocalNotification(payload)).called(1);
    });

    test('handleNotificationTap で有効なパスがある場合 GoRouter.go が呼ばれること', () async {
      final container = createContainer();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      const payload = NotificationPayload(
        path: '/memos',
        title: 'Memo',
      );

      when(() => mockRouter.go('/memos')).thenReturn(null);

      container
          .read(notificationProvider.notifier)
          .handleNotificationTap(payload);

      final state = container.read(notificationProvider);
      if (state case final NotificationStateData dataState) {
        check(dataState.latestPayload).equals(payload);
      }
      verify(() => mockRouter.go('/memos')).called(1);
    });

    test('handleNotificationTap でパスがない場合 GoRouter.go は呼ばれないこと', () async {
      final container = createContainer();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      const payload = NotificationPayload(
        title: 'No Path',
      );

      container
          .read(notificationProvider.notifier)
          .handleNotificationTap(payload);

      final state = container.read(notificationProvider);
      if (state case final NotificationStateData dataState) {
        check(dataState.latestPayload).equals(payload);
      }
      verifyNever(() => mockRouter.go(any()));
    });
  });
}
