import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
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

// 依存するプロバイダーのモック
class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockCrashlytics extends Mock implements FirebaseCrashlytics {}

class MockTalker extends Mock implements Talker {}

class MockTalkerFilter extends Mock implements TalkerFilter {}

// --- Fake Notifier ---
// UpdateRequestController の状態をコントロールするFake
class FakeUpdateRequestController extends UpdateRequestController {
  @override
  Future<UpdateRequestType> build() async {
    return UpdateRequestType.not;
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

    // L10n のスタブ設定
    when(() => mockL10n.homeTitle).thenReturn('ホーム');
    when(() => mockL10n.homeDescription).thenReturn('ホーム画面の説明');
    when(() => mockL10n.homeCurrentEnv).thenReturn('現在の環境');
    when(() => mockL10n.homeToSettings).thenReturn('設定画面へ');
    when(() => mockL10n.homeToUserList).thenReturn('ユーザー一覧へ');
    when(() => mockL10n.homeToResetPassword).thenReturn('パスワードリセットへ');
    when(() => mockL10n.homeToChat).thenReturn('チャット画面へ');
    when(() => mockL10n.homeToMemos).thenReturn('メモ一覧へ');
    when(() => mockL10n.homeToGraph).thenReturn('グラフ作成画面へ');
    when(() => mockL10n.homeToNotFound).thenReturn('存在しない画面へ');
    when(() => mockL10n.homeGetAppInfo).thenReturn('アプリ情報取得');
    when(() => mockL10n.homeAppName).thenReturn('アプリ名');
    when(() => mockL10n.homeBundleId).thenReturn('Bundle ID');
    when(() => mockL10n.homeCrashTest).thenReturn('クラッシュテスト');
    when(() => mockL10n.homeAnalyticsTest).thenReturn('分析イベント送信テスト');
    when(() => mockL10n.developerLogTitle).thenReturn('開発者ログ');
  });

  /// テスト環境のセットアップヘルパー
  Future<void> setupWidget(WidgetTester tester) async {
    attemptedPath = null;

    final dummyPackageInfo = PackageInfo(
      appName: 'テストアプリ',
      packageName: 'com.example.testapp',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'test_sig',
    );

    // ルーティングのモック（ボタンタップでクラッシュしないようにダミーを設定）
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
          flavorProvider.overrideWithValue(Flavor.local),
          useFirebaseAuthProvider.overrideWithValue(true),
          updateRequestControllerProvider.overrideWith(
            FakeUpdateRequestController.new,
          ),
          firebaseCrashlyticsProvider.overrideWithValue(mockCrashlytics),
          loggerProvider.overrideWithValue(mockTalker),
          analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
          packageInfoProvider.overrideWithValue(dummyPackageInfo),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('HomeScreen', () {
    testWidgets('初期表示: タイトルや各種ボタンが正しく表示されていること', (tester) async {
      await setupWidget(tester);

      expect(find.text('ホーム'), findsOneWidget);
      final expectedEnvText = '現在の環境: ${Flavor.local.name.toUpperCase()}';
      expect(find.text(expectedEnvText), findsOneWidget);

      final devLog = find.text('開発者ログ');
      await tester.dragUntilVisible(
        devLog,
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(devLog, findsOneWidget);

      final appName = find.text('アプリ名: ');
      await tester.dragUntilVisible(
        appName,
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(appName, findsOneWidget);
      expect(find.text('Bundle ID: '), findsOneWidget);
    });

    testWidgets('PackageInfo: アプリ情報取得ボタンを押すと、情報が読み込まれてUIが更新されること', (
      tester,
    ) async {
      await setupWidget(tester);

      // Act: アプリ情報取得ボタンをタップ
      final button = find.text('アプリ情報取得');
      await tester.dragUntilVisible(
        button,
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.tap(button);

      await tester.pump();

      // Assert: プロバイダーで注入したダミー値が反映されていること
      final appNameText = find.text('アプリ名: テストアプリ');
      await tester.dragUntilVisible(
        appNameText,
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(appNameText, findsOneWidget);
      expect(find.text('Bundle ID: com.example.testapp'), findsOneWidget);
    });

    testWidgets('Crashlytics: クラッシュテストボタンを押すと、crash メソッドが呼ばれること', (
      tester,
    ) async {
      await setupWidget(tester);

      final button = find.text('クラッシュテスト');
      await tester.dragUntilVisible(
        button,
        find.byType(ListView),
        const Offset(0, -500),
      );

      // Act
      await tester.tap(button);
      await tester.pump();

      // Assert
      verify(() => mockCrashlytics.crash()).called(1);
    });

    group('Analytics', () {
      testWidgets('正常系: ボタンを押すとイベントが送信され、TalkerのDebugが出力されること', (tester) async {
        when(
          () => mockAnalyticsService.logEvent(event: any(named: 'event')),
        ).thenAnswer((_) async {});

        await setupWidget(tester);

        final button = find.text('分析イベント送信テスト');
        await tester.dragUntilVisible(
          button,
          find.byType(ListView),
          const Offset(0, -500),
        );

        // Act
        await tester.tap(button);
        await tester.pump();

        // Assert
        verify(
          () => mockAnalyticsService.logEvent(
            event: AnalyticsEvent.homeButtonTapped,
          ),
        ).called(1);

        verify(() => mockTalker.debug(any<dynamic>())).called(1);
        verifyNever(() => mockTalker.error(any<dynamic>()));
      });

      testWidgets('異常系: イベント送信で例外が発生した場合、TalkerのErrorが出力されること', (tester) async {
        when(
          () => mockAnalyticsService.logEvent(event: any(named: 'event')),
        ).thenThrow(Exception('Analytics Error'));

        await setupWidget(tester);

        final button = find.text('分析イベント送信テスト');
        await tester.dragUntilVisible(
          button,
          find.byType(ListView),
          const Offset(0, -500),
        );

        // Act
        await tester.tap(button);
        await tester.pump();

        // Assert
        verify(
          () => mockAnalyticsService.logEvent(
            event: AnalyticsEvent.homeButtonTapped,
          ),
        ).called(1);

        verifyNever(() => mockTalker.debug(any<dynamic>()));
        verify(() => mockTalker.error(any<dynamic>())).called(1);
      });
    });
  });

  group('画面遷移 (Routing)', () {
    testWidgets('各画面への遷移ボタンを押すと、適切なパスがPush/Goされること', (tester) async {
      Future<void> tapAndVerifyRouting(
        String buttonText,
        String expectedPathFragment,
      ) async {
        await setupWidget(tester);

        attemptedPath = null;
        final button = find.text(buttonText);

        await tester.dragUntilVisible(
          button,
          find.byType(ListView),
          const Offset(0, -300),
        );

        await tester.tap(button);
        await tester.pumpAndSettle();

        expect(attemptedPath, isNotNull);
        expect(attemptedPath, contains(expectedPathFragment));
      }

      await tapAndVerifyRouting('設定画面へ', 'settings');
      await tapAndVerifyRouting('ユーザー一覧へ', 'user');
      await tapAndVerifyRouting('パスワードリセットへ', 'reset');
      await tapAndVerifyRouting('チャット画面へ', 'chat');
      await tapAndVerifyRouting('メモ一覧へ', 'memos');
      await tapAndVerifyRouting('グラフ作成画面へ', 'chart-input');
      await tapAndVerifyRouting('存在しない画面へ', 'undefined');
    });

    testWidgets('開発者ログボタンを押すと、TalkerScreenが表示されること', (tester) async {
      // TalkerScreenの描画時に呼ばれるプロパティのスタブを設定
      final mockFilter = MockTalkerFilter();
      when(() => mockFilter.enabledKeys).thenReturn([]);

      when(() => mockTalker.history).thenReturn([]);
      when(() => mockTalker.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockTalker.filter).thenReturn(mockFilter);

      await setupWidget(tester);

      final button = find.text('開発者ログ');

      await tester.dragUntilVisible(
        button,
        find.byType(ListView),
        const Offset(0, -300),
      );

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(TalkerScreen), findsOneWidget);
    });
  });
}
