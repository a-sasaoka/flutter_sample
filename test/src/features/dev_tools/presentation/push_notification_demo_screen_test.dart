import 'package:checks/checks.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/push_notification_demo_screen.dart';
import 'package:flutter_sample/src/features/notification/application/notification_notifier.dart';
import 'package:flutter_sample/src/features/notification/application/notification_state.dart';
import 'package:flutter_sample/src/features/notification/domain/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Widget buildTestWidget({
    required NotificationNotifier notifier,
  }) {
    return ProviderScope(
      overrides: [
        notificationProvider.overrideWith(() => notifier),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ja'),
        home: PushNotificationDemoScreen(),
      ),
    );
  }

  group('PushNotificationDemoScreen', () {
    testWidgets('ローディング状態のときに CircularProgressIndicator が表示されること', (
      tester,
    ) async {
      final spyNotifier = _SpyNotificationNotifier(
        const NotificationState.loading(),
      );

      await tester.pumpWidget(buildTestWidget(notifier: spyNotifier));

      check(find.byType(CircularProgressIndicator).evaluate().length).equals(1);
    });

    testWidgets('エラー状態のときにエラーメッセージが表示されること', (tester) async {
      final spyNotifier = _SpyNotificationNotifier(
        const NotificationState.error(message: 'テストエラーが発生しました'),
      );

      await tester.pumpWidget(buildTestWidget(notifier: spyNotifier));

      check(find.text('テストエラーが発生しました').evaluate().length).equals(1);
    });

    testWidgets('トークン未取得・権限未設定のときの表示確認', (tester) async {
      final spyNotifier = _SpyNotificationNotifier(
        const NotificationState.data(
          authorizationStatus: AuthorizationStatus.notDetermined,
        ),
      );

      await tester.pumpWidget(buildTestWidget(notifier: spyNotifier));

      check(
        find.text('トークン未取得（実機またはシミュレータ環境）').evaluate().length,
      ).equals(1);

      check(find.textContaining('未設定').evaluate().length).equals(1);
    });

    testWidgets('FCMトークン取得済み・コピーボタンタップで SnackBar が表示されること', (tester) async {
      final spyNotifier = _SpyNotificationNotifier(
        const NotificationState.data(
          fcmToken: 'test_fcm_token_12345',
          authorizationStatus: AuthorizationStatus.authorized,
        ),
      );

      await tester.pumpWidget(buildTestWidget(notifier: spyNotifier));

      check(find.text('test_fcm_token_12345').evaluate().length).equals(1);
      check(find.textContaining('許可').evaluate().length).equals(1);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform,
            (methodCall) async {
              return null;
            },
          );

      // コピーボタンをタップ
      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      check(find.textContaining('クリップボードにコピーしました').evaluate().length).equals(1);
    });

    testWidgets('権限リクエストボタンタップで requestPermission が呼ばれること', (tester) async {
      final spyNotifier = _SpyNotificationNotifier(
        const NotificationState.data(
          authorizationStatus: AuthorizationStatus.denied,
        ),
      );

      await tester.pumpWidget(buildTestWidget(notifier: spyNotifier));

      check(find.textContaining('拒否').evaluate().length).equals(1);

      await tester.tap(find.text('通知権限をリクエスト'));
      await tester.pump();

      check(spyNotifier.requestPermissionCallCount).equals(1);
    });

    testWidgets('各テスト通知ボタンタップで sendTestNotification が呼ばれること', (tester) async {
      final spyNotifier = _SpyNotificationNotifier(
        const NotificationState.data(
          authorizationStatus: AuthorizationStatus.provisional,
        ),
      );

      await tester.pumpWidget(buildTestWidget(notifier: spyNotifier));

      check(find.textContaining('仮許可').evaluate().length).equals(1);

      // 1. チャットテスト通知ボタンまでスクロールしてタップ
      final chatTile = find.text('AIチャット通知テスト');
      await tester.dragUntilVisible(
        chatTile,
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      final sendButtons = find.byIcon(Icons.send);
      await tester.tap(sendButtons.at(0));
      await tester.pump();

      check(spyNotifier.sentTestNotifications.length).equals(1);
      check(spyNotifier.sentTestNotifications.first.path).equals('/chat');

      // 2. メモテスト通知ボタンまでスクロールしてタップ
      final memoTile = find.text('メモ詳細通知テスト');
      await tester.dragUntilVisible(
        memoTile,
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      await tester.tap(sendButtons.at(1));
      await tester.pump();

      check(spyNotifier.sentTestNotifications.length).equals(2);
      check(spyNotifier.sentTestNotifications[1].path).equals('/memos');

      // 3. プロフィールテスト通知ボタンまでスクロールしてタップ
      final profileTile = find.text('プロフィール通知テスト');
      await tester.dragUntilVisible(
        profileTile,
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      await tester.tap(sendButtons.at(2));
      await tester.pump();

      check(spyNotifier.sentTestNotifications.length).equals(3);
      check(
        spyNotifier.sentTestNotifications[2].path,
      ).equals('/settings/profile');
    });

    testWidgets('latestPayload が存在する場合にカードが表示されること', (tester) async {
      const payload = NotificationPayload(
        path: '/chat',
        title: 'Latest Title',
        body: 'Latest Body',
      );

      final spyNotifier = _SpyNotificationNotifier(
        const NotificationState.data(
          latestPayload: payload,
        ),
      );

      await tester.pumpWidget(buildTestWidget(notifier: spyNotifier));

      final payloadLabel = find.text('最後に検知した通知ペイロード');
      await tester.dragUntilVisible(
        payloadLabel,
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      check(payloadLabel.evaluate().length).equals(1);
      check(find.textContaining('/chat').evaluate().length).equals(1);
    });
  });
}

class _SpyNotificationNotifier extends NotificationNotifier {
  _SpyNotificationNotifier(this._initialState);

  final NotificationState _initialState;
  int requestPermissionCallCount = 0;
  final List<NotificationPayload> sentTestNotifications = [];

  @override
  NotificationState build() => _initialState;

  @override
  Future<void> requestPermission() async {
    requestPermissionCallCount++;
  }

  @override
  Future<void> sendTestNotification(NotificationPayload payload) async {
    sentTestNotifications.add(payload);
  }
}
