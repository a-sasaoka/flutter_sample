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
        check(state).isA<NotificationStateData>();
        final dataState = state as NotificationStateData;
        check(dataState.initialPayload).equals(initialPayload);

        final notifier = container.read(notificationProvider.notifier);
        final consumed = notifier.consumeInitialPayload();
        check(consumed).equals(initialPayload);

        final nextState = container.read(notificationProvider);
        check(nextState).isA<NotificationStateData>();
        final nextDataState = nextState as NotificationStateData;
        check(nextDataState.initialPayload).isNull();

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
      check(state).isA<NotificationStateData>();
      final dataState = state as NotificationStateData;
      check(dataState.fcmToken).equals('updated_token_123');
    });

    test(
      '初期化中（getToken等の処理中）に onTokenRefresh が発生した場合、 '
      '更新されたトークンが反映されること',
      () async {
        final tokenCompleter = Completer<String?>();
        when(
          () => mockService.getToken(),
        ).thenAnswer((_) => tokenCompleter.future);

        final container = createContainer();

        // 初期化が開始され getToken 待ち状態になるまで少し待機
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // getToken 完了前に onTokenRefresh で新しいトークンを発行
        tokenRefreshController.add('refreshed_during_init_token');

        // getToken を完了させる（古いトークンを返す）
        tokenCompleter.complete('old_token');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = container.read(notificationProvider);
        check(state).isA<NotificationStateData>();
        final dataState = state as NotificationStateData;
        // refreshedToken が優先されていること
        check(dataState.fcmToken).equals('refreshed_during_init_token');
      },
    );

    test('container が dispose された後の onTokenRefresh は無視されること', () async {
      var notificationCount = 0;
      final container =
          ProviderContainer(
            overrides: [
              pushNotificationServiceProvider.overrideWithValue(mockService),
              routerProvider.overrideWithValue(mockRouter),
            ],
          )..listen(notificationProvider, (previous, next) {
            notificationCount++;
          });
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final countBeforeDispose = notificationCount;
      check(countBeforeDispose).isGreaterThan(0);

      container.dispose();
      tokenRefreshController.add('ignore_token');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      check(notificationCount).equals(countBeforeDispose);
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
      check(state).isA<NotificationStateData>();
      final dataState = state as NotificationStateData;
      check(
        dataState.authorizationStatus,
      ).equals(AuthorizationStatus.authorized);
    });

    test('requestPermission で settings が null の場合ステータスは変化しないこと', () async {
      final container = createContainer();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      when(() => mockService.requestPermission()).thenAnswer((_) async => null);

      await container.read(notificationProvider.notifier).requestPermission();

      final state = container.read(notificationProvider);
      check(state).isA<NotificationStateData>();
      final dataState = state as NotificationStateData;
      check(dataState.authorizationStatus).isNull();
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

    test(
      'handleNotificationTap で latestPayload と lastReceivedPayload が更新され '
      'consumeLatestPayload で latestPayload が消費されても '
      'lastReceivedPayload は維持されること',
      () async {
        final container = createContainer();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        const payload = NotificationPayload(
          path: '/memos',
          title: 'Memo',
        );

        final notifier = container.read(notificationProvider.notifier)
          ..handleNotificationTap(payload);

        final state = container.read(notificationProvider);
        check(state).isA<NotificationStateData>();
        final dataState = state as NotificationStateData;
        check(dataState.latestPayload).equals(payload);
        check(dataState.lastReceivedPayload).equals(payload);

        // consumeLatestPayload で latestPayload が取り出され、null に更新されるが
        // lastReceivedPayload は維持されること
        final consumed = notifier.consumeLatestPayload();
        check(consumed).equals(payload);

        final afterState = container.read(notificationProvider);
        check(afterState).isA<NotificationStateData>();
        final afterDataState = afterState as NotificationStateData;
        check(afterDataState.latestPayload).isNull();
        check(afterDataState.lastReceivedPayload).equals(payload);

        // 2回目の消費は null
        check(notifier.consumeLatestPayload()).isNull();
      },
    );

    test(
      '初期化処理中（loading中）に handleNotificationTap が呼ばれた場合、 '
      '初期化完了時に latestPayload および lastReceivedPayload へ反映されること',
      () async {
        final initCompleter = Completer<String?>();
        when(
          () => mockService.getToken(),
        ).thenAnswer((_) => initCompleter.future);

        final container = createContainer();

        // 初期化中（loading中）であることを確認
        check(
          container.read(notificationProvider),
        ).isA<NotificationStateLoading>();

        const pendingPayload = NotificationPayload(
          path: '/chat',
          title: 'Pending Chat',
        );

        // loading 中にタップハンドラが呼ばれる
        container
            .read(notificationProvider.notifier)
            .handleNotificationTap(pendingPayload);

        // 初期化処理を完了させる
        initCompleter.complete('fcm_token_123');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = container.read(notificationProvider);
        check(state).isA<NotificationStateData>();
        final dataState = state as NotificationStateData;
        check(dataState.latestPayload).equals(pendingPayload);
        check(dataState.lastReceivedPayload).equals(pendingPayload);
      },
    );
  });
}
