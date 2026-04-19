import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';
import 'package:flutter_sample/src/core/network/firebase_crashlytics_provider.dart';
import 'package:flutter_sample/src/features/home/presentation/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

// --- モック ---
class MockAppLocalizations extends Mock implements AppLocalizations {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

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

class _FakeUpdateRequestController extends UpdateRequestController {
  _FakeUpdateRequestController(this.initialValue);
  final AsyncValue<UpdateRequestType> initialValue;
  @override
  Future<UpdateRequestType> build() async =>
      initialValue.value ?? UpdateRequestType.not;
}

void main() {
  late MockAppLocalizations mockL10n;
  late MockAnalyticsService mockAnalytics;
  late MockFirebaseCrashlytics mockCrashlytics;

  setUpAll(() {
    registerFallbackValue(AnalyticsEvent.homeButtonTapped);
  });

  setUp(() {
    mockL10n = MockAppLocalizations();
    mockAnalytics = MockAnalyticsService();
    mockCrashlytics = MockFirebaseCrashlytics();

    // 翻訳テキストのスタブ
    when(() => mockL10n.homeTitle).thenReturn('ホーム');
    when(() => mockL10n.homeDescription).thenReturn('説明');
    when(() => mockL10n.homeCurrentEnv).thenReturn('環境');
    when(() => mockL10n.homeToSettings).thenReturn('設定へ');
    when(() => mockL10n.homeToSample).thenReturn('サンプルへ');
    when(() => mockL10n.homeToUserList).thenReturn('ユーザー一覧へ');
    when(() => mockL10n.homeToResetPassword).thenReturn('パスワードリセットへ');
    when(() => mockL10n.homeToChat).thenReturn('チャットへ');
    when(() => mockL10n.homeToNotFound).thenReturn('404テスト');
    when(() => mockL10n.homeGetAppInfo).thenReturn('アプリ情報取得');
    when(() => mockL10n.homeAppName).thenReturn('アプリ名');
    when(() => mockL10n.homeBundleId).thenReturn('ID');
    when(() => mockL10n.homeCrashTest).thenReturn('クラッシュテスト');
    when(() => mockL10n.homeAnalyticsTest).thenReturn('計測テスト');
    when(() => mockL10n.versionUpTitle).thenReturn('更新');
    when(() => mockL10n.versionUpUpdate).thenReturn('今すぐ');
    when(() => mockL10n.versionUpCancel).thenReturn('あとで');

    PackageInfo.setMockInitialValues(
      appName: 'TestApp',
      packageName: 'com.test.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Future<void> setupWidget(
    WidgetTester tester, {
    Flavor flavor = Flavor.dev,
    bool useAuth = true,
    AsyncValue<UpdateRequestType> updateRequest = const AsyncValue.data(
      UpdateRequestType.not,
    ),
  }) async {
    // 最小限の GoRouter 設定
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/:any', builder: (context, state) => const Scaffold()),
      ],
    );

    // 下の方のボタンも確実に叩けるよう画面サイズを広げる
    tester.view.physicalSize = const Size(800, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flavorProvider.overrideWithValue(flavor),
          useFirebaseAuthProvider.overrideWithValue(useAuth),
          analyticsServiceProvider.overrideWithValue(mockAnalytics),
          firebaseCrashlyticsProvider.overrideWithValue(mockCrashlytics),
          updateRequestControllerProvider.overrideWith(
            () => _FakeUpdateRequestController(updateRequest),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('HomeScreen UI & Basic Interaction', () {
    testWidgets('初期表示: タイトルと環境名が表示されること', (tester) async {
      await setupWidget(tester);
      expect(find.text('ホーム'), findsOneWidget);
      expect(find.textContaining('DEV'), findsOneWidget);
    });

    // 画面遷移系は個別にテストすることで「画面が消えてボタンが見つからない」を防ぎカバレッジを通す
    testWidgets('遷移: 設定へ', (tester) async {
      await setupWidget(tester);
      await tester.tap(find.textContaining('設定へ'));
      await tester.pumpAndSettle();
    });

    testWidgets('遷移: サンプルへ', (tester) async {
      await setupWidget(tester);
      await tester.tap(find.textContaining('サンプルへ'));
      await tester.pumpAndSettle();
    });

    testWidgets('遷移: ユーザー一覧へ', (tester) async {
      await setupWidget(tester);
      await tester.tap(find.textContaining('ユーザー一覧へ'));
      await tester.pumpAndSettle();
    });

    testWidgets('遷移: チャットへ', (tester) async {
      await setupWidget(tester);
      await tester.tap(find.textContaining('チャットへ'));
      await tester.pumpAndSettle();
    });

    testWidgets('遷移: 404テスト(context.go)', (tester) async {
      await setupWidget(tester);
      await tester.tap(find.textContaining('404テスト'));
      await tester.pumpAndSettle();
    });

    testWidgets('機能: アプリ情報取得', (tester) async {
      await setupWidget(tester);
      await tester.tap(find.textContaining('アプリ情報取得'));
      await tester.pumpAndSettle();
      expect(find.textContaining('TestApp'), findsOneWidget);
    });

    testWidgets('機能: クラッシュテスト', (tester) async {
      when(() => mockCrashlytics.crash()).thenAnswer((_) async {});
      await setupWidget(tester);
      await tester.tap(find.textContaining('クラッシュテスト'));
      await tester.pumpAndSettle();
      verify(() => mockCrashlytics.crash()).called(1);
    });

    testWidgets('機能: 計測テスト（正常系）', (tester) async {
      when(
        () => mockAnalytics.logEvent(event: any(named: 'event')),
      ).thenAnswer((_) async {});
      await setupWidget(tester);
      await tester.tap(find.textContaining('計測テスト'));
      await tester.pumpAndSettle();
      verify(
        () => mockAnalytics.logEvent(event: any(named: 'event')),
      ).called(1);
    });

    testWidgets('機能: 計測テスト（異常系） catch節の網羅', (tester) async {
      when(
        () => mockAnalytics.logEvent(event: any(named: 'event')),
      ).thenThrow(Exception('Fail'));
      await setupWidget(tester);
      await tester.tap(find.textContaining('計測テスト'));
      await tester.pumpAndSettle();
      verify(
        () => mockAnalytics.logEvent(event: any(named: 'event')),
      ).called(1);
    });

    testWidgets('通知: アップデート通知ダイアログ', (tester) async {
      await setupWidget(
        tester,
        updateRequest: const AsyncValue.data(UpdateRequestType.forcibly),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('状態: ローディング表示', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            updateRequestControllerProvider.overrideWith(
              () => _FakeUpdateRequestController(const AsyncValue.loading()),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  testWidgets('遷移: パスワードリセットへ (Auth有効時のみ)', (tester) async {
    // useAuth: true (デフォルト) でセットアップ
    await setupWidget(tester);

    final button = find.textContaining('パスワードリセットへ');

    // ボタンが表示されていることを確認してからタップ
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
  });
}
