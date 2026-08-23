import 'package:checks/checks.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/notification/application/notification_notifier.dart';
import 'package:flutter_sample/src/features/notification/application/notification_state.dart';
import 'package:flutter_sample/src/features/notification/presentation/notification_prompt_banner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _MockNotificationNotifier extends NotificationNotifier {
  _MockNotificationNotifier({
    this.initialState = const NotificationState.data(
      authorizationStatus: AuthorizationStatus.notDetermined,
    ),
  });

  final NotificationState initialState;
  int requestPermissionCallCount = 0;

  @override
  NotificationState build() => initialState;

  @override
  Future<void> requestPermission() async {
    requestPermissionCallCount++;
  }
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ja'));
  });

  Future<void> pumpBanner(
    WidgetTester tester, {
    required _MockNotificationNotifier notifier,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
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
          home: Scaffold(
            body: NotificationPromptBanner(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('NotificationPromptBanner ウィジェットテスト', () {
    testWidgets('authorized (許可済み) のときはバナーが表示されないこと', (tester) async {
      final notifier = _MockNotificationNotifier(
        initialState: const NotificationState.data(
          authorizationStatus: AuthorizationStatus.authorized,
        ),
      );

      await pumpBanner(tester, notifier: notifier);

      check(find.text(l10n.notificationBannerTitle)).findsNothing();
    });

    testWidgets('provisional (仮許可) のときはバナーが表示されないこと', (tester) async {
      final notifier = _MockNotificationNotifier(
        initialState: const NotificationState.data(
          authorizationStatus: AuthorizationStatus.provisional,
        ),
      );

      await pumpBanner(tester, notifier: notifier);

      check(find.text(l10n.notificationBannerTitle)).findsNothing();
    });

    testWidgets('loading状態のときはバナーが表示されないこと', (tester) async {
      final notifier = _MockNotificationNotifier(
        initialState: const NotificationState.loading(),
      );

      await pumpBanner(tester, notifier: notifier);

      check(find.text(l10n.notificationBannerTitle)).findsNothing();
    });

    testWidgets(
      'notDetermined (未設定) のとき、バナーと「通知をオンにする」ボタンが表示されタップで権限リクエストされること',
      (tester) async {
        final notifier = _MockNotificationNotifier();

        await pumpBanner(tester, notifier: notifier);

        // タイトルと説明文が表示されること
        check(find.text(l10n.notificationBannerTitle)).findsOne();
        check(find.text(l10n.notificationBannerBody)).findsOne();
        check(find.text(l10n.notificationBannerEnableButton)).findsOne();

        // 「通知をオンにする」をタップ
        await tester.tap(find.text(l10n.notificationBannerEnableButton));
        await tester.pump();

        check(notifier.requestPermissionCallCount).equals(1);
      },
    );

    testWidgets('denied (拒否) のとき、「設定を開く」ボタンが表示されタップで設定を開くこと', (tester) async {
      final notifier = _MockNotificationNotifier(
        initialState: const NotificationState.data(
          authorizationStatus: AuthorizationStatus.denied,
        ),
      );

      final methodCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.spencerccf.app_settings/methods'),
            (methodCall) async {
              methodCalls.add(methodCall);
              return null;
            },
          );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('com.spencerccf.app_settings/methods'),
              null,
            );
      });

      await pumpBanner(tester, notifier: notifier);

      // 「設定を開く」ボタンが表示されること
      check(find.text(l10n.notificationBannerSettingsButton)).findsOne();
      check(find.text(l10n.notificationBannerEnableButton)).findsNothing();

      // 「設定を開く」ボタンをタップ
      await tester.tap(find.text(l10n.notificationBannerSettingsButton));
      await tester.pump();

      check(methodCalls).isNotEmpty();
      check(methodCalls.first.method).equals('openSettings');
    });

    testWidgets('閉じる(✕)ボタンをタップするとバナーが非表示になること', (tester) async {
      final notifier = _MockNotificationNotifier();

      await pumpBanner(tester, notifier: notifier);

      check(find.text(l10n.notificationBannerTitle)).findsOne();

      // ✕ボタンをタップ
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      check(find.text(l10n.notificationBannerTitle)).findsNothing();
    });
  });
}
