import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';
import 'package:flutter_sample/src/core/network/firebase_crashlytics_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/package_info_provider.dart';
import 'package:flutter_sample/src/features/home/presentation/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

// --- モッククラスの定義 ---

class MockAppLocalizations extends Mock implements AppLocalizations {}

class _MockLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _MockLocalizationsDelegate(this.mock);
  final MockAppLocalizations mock;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => mock;
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockCrashlytics extends Mock implements FirebaseCrashlytics {}

class MockTalker extends Mock implements Talker {}

class MockTalkerFilter extends Mock implements TalkerFilter {}

class FakeUpdateRequestController extends UpdateRequestController {
  FakeUpdateRequestController({bool startLoading = false})
    : _startLoading = startLoading;
  final bool _startLoading;
  final _completer = Completer<UpdateRequestType>();

  @override
  Future<UpdateRequestType> build() async {
    if (_startLoading) {
      return _completer.future;
    }
    return UpdateRequestType.not;
  }

  void emit(UpdateRequestType type) {
    state = AsyncData(type);
  }

  void complete(UpdateRequestType type) {
    _completer.complete(type);
  }
}

class FakeCancelController extends CancelController {
  FakeCancelController({required bool initialValue})
    : _initialValue = initialValue;
  final bool _initialValue;
  @override
  bool build() => _initialValue;

  @override
  void clickCancel() {
    state = true;
  }
}

void main() {
  late MockAppLocalizations mockL10n;
  late MockAnalyticsService mockAnalyticsService;
  late MockCrashlytics mockCrashlytics;
  late MockTalker mockTalker;

  String? attemptedPath;

  setUpAll(() {
    registerFallbackValue(AnalyticsEvent.homeButtonTapped);
  });

  setUp(() {
    mockL10n = MockAppLocalizations();
    mockAnalyticsService = MockAnalyticsService();
    mockCrashlytics = MockCrashlytics();
    mockTalker = MockTalker();

    when(() => mockL10n.homeTitle).thenReturn('ホーム');
    when(() => mockL10n.homeDescription).thenReturn('ホーム画面の説明');
    when(() => mockL10n.homeCurrentEnv).thenReturn('現在の環境');
    when(() => mockL10n.homeToSettings).thenReturn('設定');
    when(() => mockL10n.homeToUserList).thenReturn('ユーザー一覧');
    when(() => mockL10n.homeToResetPassword).thenReturn('パスワードリセット');
    when(() => mockL10n.homeToChat).thenReturn('AIチャット');
    when(() => mockL10n.homeToMemos).thenReturn('メモ帳');
    when(() => mockL10n.homeToGraph).thenReturn('グラフ');
    when(() => mockL10n.homeToNotFound).thenReturn('404テスト');
    when(() => mockL10n.homeGetAppInfo).thenReturn('アプリ情報取得');
    when(() => mockL10n.homeAppName).thenReturn('アプリ名');
    when(() => mockL10n.homeBundleId).thenReturn('Bundle ID');
    when(() => mockL10n.homeCrashTest).thenReturn('クラッシュテスト');
    when(() => mockL10n.homeAnalyticsTest).thenReturn('分析テスト');
    when(() => mockL10n.developerLogTitle).thenReturn('開発者ログ');
    when(() => mockL10n.versionUpTitle).thenReturn('アップデート');
    when(() => mockL10n.versionUpMessageOptional).thenReturn('オプション');
    when(() => mockL10n.versionUpMessageMandatory).thenReturn('必須');
    when(() => mockL10n.versionUpUpdate).thenReturn('更新');
    when(() => mockL10n.versionUpCancel).thenReturn('後で');
    when(() => mockL10n.close).thenReturn('閉じる');
    when(() => mockL10n.ok).thenReturn('OK');
  });

  Future<void> setupWidget(
    WidgetTester tester, {
    FakeUpdateRequestController? controller,
    Flavor flavor = Flavor.local,
    bool cancelAlreadyPressed = false,
  }) async {
    attemptedPath = null;

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final dummyPackageInfo = PackageInfo(
      appName: 'テストアプリ',
      packageName: 'com.example.testapp',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'test_sig',
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
      ],
      errorBuilder: (context, state) {
        attemptedPath = state.uri.toString();
        return const Scaffold(body: Text('Dummy Error Screen'));
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flavorProvider.overrideWithValue(flavor),
          envConfigProvider.overrideWithValue(
            const EnvConfigState(
              baseUrl: 'https://test.example.com',
              aiModel: 'test-model',
              connectTimeout: 10,
              receiveTimeout: 15,
              sendTimeout: 10,
              useFirebaseAuth: true,
            ),
          ),
          updateRequestControllerProvider.overrideWith(
            () => controller ?? FakeUpdateRequestController(),
          ),
          cancelControllerProvider.overrideWith(
            () => FakeCancelController(initialValue: cancelAlreadyPressed),
          ),
          firebaseCrashlyticsProvider.overrideWithValue(mockCrashlytics),
          loggerProvider.overrideWithValue(mockTalker),
          analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
          packageInfoProvider.overrideWithValue(dummyPackageInfo),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: [
            _MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
    await tester.pump();
  }

  group('HomeScreen', () {
    testWidgets('初期表示: タイトルや環境情報、メニューが正しく表示されていること', (tester) async {
      await setupWidget(tester);
      await tester.pumpAndSettle();

      expect(find.text('ホーム'), findsOneWidget);
      expect(find.text('現在の環境'), findsOneWidget);
      expect(find.text('LOCAL'), findsOneWidget);

      expect(find.widgetWithText(ListTile, 'AIチャット'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'メモ帳'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'グラフ'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'ユーザー一覧'), findsOneWidget);
    });

    testWidgets('アップデート通知: 新しいバージョンがある場合にダイアログが表示されること', (tester) async {
      final controller = FakeUpdateRequestController();
      await setupWidget(tester, controller: controller);
      await tester.pumpAndSettle();

      controller.emit(UpdateRequestType.cancelable);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('アップデート'), findsOneWidget);

      await tester.tap(find.text('後で'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('アップデート通知: 強制アップデートの場合に「後で」ボタンがないこと', (tester) async {
      final controller = FakeUpdateRequestController();
      await setupWidget(tester, controller: controller);
      await tester.pumpAndSettle();

      controller.emit(UpdateRequestType.forcibly);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('後で'), findsNothing);

      when(() => mockTalker.info(any<dynamic>())).thenReturn(null);
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();
      verify(() => mockTalker.info('Update button tapped')).called(1);
    });

    testWidgets('アップデート通知: すでにキャンセル済みの場合はダイアログが表示されないこと', (tester) async {
      final controller = FakeUpdateRequestController();
      await setupWidget(
        tester,
        controller: controller,
        cancelAlreadyPressed: true,
      );
      await tester.pumpAndSettle();

      controller.emit(UpdateRequestType.cancelable);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('エラー表示: アップデート情報の取得に失敗した場合でもアプリ情報取得が動作すること', (
      tester,
    ) async {
      final controller = FakeUpdateRequestController();
      await setupWidget(tester, controller: controller);
      await tester.pumpAndSettle();

      controller.state = const AsyncError('Fetch Error', StackTrace.empty);
      await tester.pumpAndSettle();

      // エラー時も buildBody() が呼ばれ、メニューが表示されていることを確認
      expect(find.widgetWithText(ListTile, 'AIチャット'), findsOneWidget);

      final buttonFinder = find.widgetWithText(FilledButton, 'アプリ情報取得');
      await tester.dragUntilVisible(
        buttonFinder,
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.text('テストアプリ'), findsOneWidget);
    });

    testWidgets('ローディング状態: インジケータが表示されること', (tester) async {
      final controller = FakeUpdateRequestController(startLoading: true);
      await setupWidget(tester, controller: controller);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.complete(UpdateRequestType.not);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('PackageInfo: アプリ情報取得ボタンを押すと、情報が読み込まれてUIが更新されること', (
      tester,
    ) async {
      await setupWidget(tester);
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(FilledButton, 'アプリ情報取得');
      await tester.dragUntilVisible(
        buttonFinder,
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.text('テストアプリ'), findsOneWidget);
      expect(find.text('com.example.testapp'), findsOneWidget);
    });

    testWidgets('開発者ログ: ボタンを押すとTalkerScreenへ遷移すること', (tester) async {
      final mockFilter = MockTalkerFilter();
      when(() => mockFilter.enabledKeys).thenReturn([]);
      when(() => mockTalker.filter).thenReturn(mockFilter);
      when(() => mockTalker.history).thenReturn([]);
      when(() => mockTalker.stream).thenAnswer((_) => const Stream.empty());

      await setupWidget(tester);
      await tester.pumpAndSettle();

      final menuBtn = find.widgetWithText(ListTile, '開発者ログ');
      await tester.dragUntilVisible(
        menuBtn,
        find.byType(ListView),
        const Offset(0, -300),
      );

      await tester.tap(menuBtn);
      await tester.pumpAndSettle();

      expect(find.byType(TalkerScreen), findsOneWidget);
    });

    testWidgets('Crashlytics: クラッシュテストボタンを押すと、crash メソッドが呼ばれること', (
      tester,
    ) async {
      await setupWidget(tester);
      await tester.pumpAndSettle();

      final menuBtn = find.widgetWithText(ListTile, 'クラッシュテスト');
      await tester.dragUntilVisible(
        menuBtn,
        find.byType(ListView),
        const Offset(0, -300),
      );

      await tester.tap(menuBtn);
      await tester.pump();

      verify(() => mockCrashlytics.crash()).called(1);
    });

    group('Analytics', () {
      testWidgets('正常系: ボタンを押すとイベントが送信されること', (tester) async {
        when(
          () => mockAnalyticsService.logEvent(
            event: any<AnalyticsEvent>(named: 'event'),
          ),
        ).thenAnswer((_) async {});
        when(() => mockTalker.debug(any<dynamic>())).thenReturn(null);

        await setupWidget(tester);
        await tester.pumpAndSettle();

        final button = find.widgetWithText(ListTile, '分析テスト');
        await tester.dragUntilVisible(
          button,
          find.byType(ListView),
          const Offset(0, -500),
        );

        await tester.tap(button);
        await tester.pump();

        verify(
          () => mockAnalyticsService.logEvent(
            event: AnalyticsEvent.homeButtonTapped,
          ),
        ).called(1);
        verify(() => mockTalker.debug(any<dynamic>())).called(1);
      });

      testWidgets('異常系: 送信エラー時にログが出力されること', (tester) async {
        when(
          () => mockAnalyticsService.logEvent(
            event: any<AnalyticsEvent>(named: 'event'),
          ),
        ).thenThrow(Exception('Analytics error'));
        when(() => mockTalker.error(any<dynamic>())).thenReturn(null);

        await setupWidget(tester);
        await tester.pumpAndSettle();

        final button = find.widgetWithText(ListTile, '分析テスト');
        await tester.dragUntilVisible(
          button,
          find.byType(ListView),
          const Offset(0, -500),
        );

        await tester.tap(button);
        await tester.pump();

        verify(() => mockTalker.error(any<dynamic>())).called(1);
      });
    });

    testWidgets('PROD環境では開発者ログのメニューが表示されないこと', (tester) async {
      await setupWidget(tester, flavor: Flavor.prod);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, '開発者ログ'), findsNothing);
    });
  });

  group('画面遷移 (Routing)', () {
    testWidgets('各画面への遷移アクションが動作すること', (tester) async {
      Future<void> tapAndVerify(String text, String path) async {
        await setupWidget(tester);
        await tester.pumpAndSettle();
        final finder = find.widgetWithText(ListTile, text);
        await tester.dragUntilVisible(
          finder,
          find.byType(ListView),
          const Offset(0, -500),
        );
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(attemptedPath, contains(path));
      }

      await tapAndVerify('AIチャット', 'chat');
      await tapAndVerify('メモ帳', 'memos');
      await tapAndVerify('グラフ', 'chart-input');
      await tapAndVerify('ユーザー一覧', 'user');
      await tapAndVerify('パスワードリセット', 'reset');
      await tapAndVerify('404テスト', 'undefined');
    });

    testWidgets('AppBarの設定アイコンから設定画面へ遷移すること', (tester) async {
      await setupWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(attemptedPath, contains('settings'));
    });
  });
}
