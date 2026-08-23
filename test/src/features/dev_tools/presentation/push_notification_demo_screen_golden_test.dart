import 'package:alchemist/alchemist.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/push_notification_demo_screen.dart';
import 'package:flutter_sample/src/features/notification/application/notification_notifier.dart';
import 'package:flutter_sample/src/features/notification/application/notification_state.dart';
import 'package:flutter_sample/src/features/notification/domain/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../golden_test_helper.dart';

void main() {
  group('PushNotificationDemoScreen Golden Tests', () {
    const dummyPayload = NotificationPayload(
      path: '/chat',
      title: 'AI Chat Update',
      body: 'You received a new response.',
    );

    const dummyState = NotificationState.data(
      fcmToken: 'sample_fcm_token_for_golden_test_1234567890',
      authorizationStatus: AuthorizationStatus.authorized,
      latestPayload: dummyPayload,
    );

    Widget buildScreen({required ThemeMode themeMode}) {
      return ProviderScope(
        overrides: [
          notificationProvider.overrideWith(
            () => _FakeNotificationNotifier(dummyState),
          ),
        ],
        child: buildGoldenTestApp(
          home: const PushNotificationDemoScreen(),
          themeMode: themeMode,
        ),
      );
    }

    // alchemistのgoldenTestは非同期処理ですが、テスト定義内で直接呼び出すため discarded_futures を無視します。
    // ignore: discarded_futures
    goldenTest(
      'PushNotificationDemoScreen の描画 (ライト/ダークモード)',
      fileName: 'push_notification_demo_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 1000,
              child: buildScreen(themeMode: ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 1000,
              child: buildScreen(themeMode: ThemeMode.dark),
            ),
          ),
        ],
      ),
    );
  });
}

class _FakeNotificationNotifier extends NotificationNotifier {
  _FakeNotificationNotifier(this._initialState);

  final NotificationState _initialState;

  @override
  NotificationState build() => _initialState;
}
