// ignore_for_file: prefer_const_constructors, document_ignores
import 'dart:async';

import 'package:checks/checks.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/app/router/main_shell_screen.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/analytics/typed_route_analytics_observer.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/widgets/not_found_screen.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_email_verification_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_login_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_reset_password_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_sign_up_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/login_screen.dart';
import 'package:flutter_sample/src/features/chart/presentation/chart_display_screen.dart';
import 'package:flutter_sample/src/features/chart/presentation/chart_input_screen.dart';
import 'package:flutter_sample/src/features/chat/data/chat_provider.dart';
import 'package:flutter_sample/src/features/chat/data/chat_repository.dart';
import 'package:flutter_sample/src/features/chat/presentation/chat_screen.dart';
import 'package:flutter_sample/src/features/home/presentation/home_screen.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_sample/src/features/memos/presentation/memo_screen.dart';
import 'package:flutter_sample/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:flutter_sample/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_sample/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_screen.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_state_provider.dart';
import 'package:flutter_sample/src/features/user/presentation/user_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class MockTalker extends Mock implements Talker {}

class MockGoRouterState extends Mock implements GoRouterState {}

class MockBuildContext extends Mock implements BuildContext {}

class MockUser extends Mock implements User {}

class MockStatefulNavigationShell extends Mock
    implements StatefulNavigationShell {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      super.toString();
}

class MockChatRepository extends Mock implements ChatRepository {}

class MockMemoRepository extends Mock implements MemoRepository {}

// --- SplashStateのフェイク定義 ---
class FakeSplashState extends SplashState {
  FakeSplashState({required this.initialValue});
  final bool initialValue;

  @override
  bool build() => initialValue;
}

class _FakeAuthStateNotifier extends AuthStateNotifier {
  _FakeAuthStateNotifier({required this.isLoggedIn});
  final bool isLoggedIn;
  @override
  Future<bool> build() async => isLoggedIn;

  void changeState({required bool value}) {
    state = AsyncData(value);
  }
}

class _FakeFirebaseAuthStateNotifier extends FirebaseAuthStateNotifier {
  _FakeFirebaseAuthStateNotifier({required this.isLoggedIn, this.mockUser});
  final bool isLoggedIn;
  final User? mockUser;

  @override
  AsyncValue<User?> build() {
    return isLoggedIn ? AsyncData(mockUser) : const AsyncData(null);
  }

  // 外部からFirebaseのログイン状態を強制的に変更するメソッド
  void changeState(User? user) {
    state = AsyncData(user);
  }
}

class _FakeOnboardingNotifier extends OnboardingNotifier {
  _FakeOnboardingNotifier({required this.completed});
  final bool completed;

  @override
  FutureOr<bool> build() => completed;

  @override
  Future<void> complete() async {
    state = const AsyncData(true);
  }
}

void main() {
  late MockFirebaseAnalytics mockAnalytics;
  late MockTalker mockTalker;
  late MockUser mockUser;
  late MockChatRepository mockChatRepository;
  late MockMemoRepository mockMemoRepository;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    mockTalker = MockTalker();
    mockUser = MockUser();
    mockChatRepository = MockChatRepository();
    mockMemoRepository = MockMemoRepository();

    when(
      () => mockMemoRepository.getAllMemos(),
    ).thenAnswer((_) async => <MemoModel>[]);
    when(
      () => mockMemoRepository.watchAllMemos(),
    ).thenAnswer((_) => Stream.value(<MemoModel>[]));
    when(
      () => mockMemoRepository.fetchAndMergeRemoteMemos(),
    ).thenAnswer((_) async {});

    when(() => mockUser.uid).thenReturn('dummy_uid_123');
    when(() => mockUser.emailVerified).thenReturn(true);
    when(() => mockUser.isAnonymous).thenReturn(false);
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.displayName).thenReturn('Test User');
    when(() => mockUser.phoneNumber).thenReturn(null);
    when(() => mockUser.photoURL).thenReturn(null);
    when(() => mockUser.tenantId).thenReturn(null);
    when(() => mockUser.refreshToken).thenReturn('dummy_token');

    when(
      () => mockAnalytics.logScreenView(
        screenClass: any(named: 'screenClass'),
        screenName: any(named: 'screenName'),
      ),
    ).thenAnswer((_) async {});
  });

  final testLocalizations = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  ProviderContainer createContainer({
    required bool isLoggedIn,
    required bool useFirebase,
    bool isSplashFinished = true,
    bool isOnboardingCompleted = true,
  }) {
    final fakeNotifier = _FakeFirebaseAuthStateNotifier(
      isLoggedIn: isLoggedIn,
      mockUser: mockUser,
    );

    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(mockChatRepository),
        memoRepositoryProvider.overrideWithValue(mockMemoRepository),
        firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
        loggerProvider.overrideWithValue(mockTalker),
        flavorProvider.overrideWithValue(Flavor.dev),
        envConfigProvider.overrideWithValue(
          EnvConfigState(
            baseUrl: 'https://test.example.com',
            aiModel: 'test-model',
            connectTimeout: 10,
            receiveTimeout: 15,
            sendTimeout: 10,
            useFirebaseAuth: useFirebase,
          ),
        ),
        authStateProvider.overrideWith(
          () => _FakeAuthStateNotifier(isLoggedIn: isLoggedIn),
        ),
        firebaseAuthStateProvider.overrideWith(
          () => fakeNotifier,
        ),
        splashStateProvider.overrideWith(
          () => FakeSplashState(initialValue: isSplashFinished),
        ),
        onboardingProvider.overrideWith(
          () => _FakeOnboardingNotifier(completed: isOnboardingCompleted),
        ),
      ],
    )..listen(routerProvider, (_, _) {});
    return container;
  }

  Widget createTestWidget(WidgetTester tester, ProviderContainer container) {
    // 画面サイズを固定し、テスト終了時にリセットする
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: container.read(routerProvider),
        localizationsDelegates: testLocalizations,
        supportedLocales: const [Locale('ja')],
      ),
    );
  }

  Future<void> teardownWidget(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    container.dispose();
    await tester.pump(const Duration(seconds: 5));
  }

  group('AppRouter リダイレクト・ルーティング統合テスト', () {
    testWidgets('ログイン済みの時、HomeScreen が表示されること', (tester) async {
      final container = createContainer(isLoggedIn: true, useFirebase: true);

      await tester.pumpWidget(createTestWidget(tester, container));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      check(find.byType(HomeScreen)).findsOne();
      await teardownWidget(tester, container);
    });

    testWidgets('未ログインかつ Firebase 未使用の時、通常 LoginScreen が表示されること', (
      tester,
    ) async {
      final container = createContainer(isLoggedIn: false, useFirebase: false);

      await tester.pumpWidget(createTestWidget(tester, container));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      check(find.byType(LoginScreen)).findsOne();
      await teardownWidget(tester, container);
    });

    testWidgets('未ログインかつ Firebase 使用の時、FirebaseLoginScreen が表示されること', (
      tester,
    ) async {
      final container = createContainer(isLoggedIn: false, useFirebase: true);

      await tester.pumpWidget(createTestWidget(tester, container));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      check(find.byType(FirebaseLoginScreen)).findsOne();
      await teardownWidget(tester, container);
    });

    testWidgets('存在しないパスにアクセスした時、NotFoundScreenが表示されること', (tester) async {
      final container = createContainer(isLoggedIn: true, useFirebase: false);

      await tester.pumpWidget(createTestWidget(tester, container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      container.read(routerProvider).go('/not-found-path-123');

      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      check(find.byType(NotFoundScreen)).findsOne();
      await teardownWidget(tester, container);
    });

    testWidgets('認証状態の変更を検知してルーターが更新（Listen）されること', (tester) async {
      final container = createContainer(isLoggedIn: false, useFirebase: true);

      await tester.pumpWidget(createTestWidget(tester, container));
      await tester.pumpAndSettle();

      // 最初は未ログインなので FirebaseLoginScreen が表示されていること
      check(find.byType(FirebaseLoginScreen)).findsOne();

      // firebaseAuthStateProvider の状態を強制的に変更する
      (container.read(firebaseAuthStateProvider.notifier)
              as _FakeFirebaseAuthStateNotifier)
          .changeState(mockUser);

      // 遷移が完了するまで待つ
      await tester.pumpAndSettle();

      // ログイン状態になったので HomeScreen に遷移することを確認
      check(find.byType(HomeScreen)).findsOne();

      await teardownWidget(tester, container);
    });

    testWidgets('スプラッシュ画面完了時にルーターが再評価されること', (tester) async {
      final container = createContainer(
        isLoggedIn: true,
        useFirebase: false,
        isSplashFinished: false,
      );

      await tester.pumpWidget(createTestWidget(tester, container));
      await tester.pump();

      // 最初はスプラッシュ未完了なので SplashScreen が表示されていること
      check(find.byType(SplashScreen)).findsOne();

      // スプラッシュ完了状態にする
      container.read(splashStateProvider.notifier).finishSplash();
      await tester.pumpAndSettle();

      // スプラッシュが完了したので HomeScreen に遷移すること
      check(find.byType(HomeScreen)).findsOne();

      await teardownWidget(tester, container);
    });

    testWidgets(
      'ログイン中かつメール未認証の時、FirebaseEmailVerificationScreen にリダイレクトされること',
      (
        tester,
      ) async {
        when(() => mockUser.emailVerified).thenReturn(false);

        final container = createContainer(isLoggedIn: true, useFirebase: true);

        await tester.pumpWidget(createTestWidget(tester, container));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        check(find.byType(FirebaseEmailVerificationScreen)).findsOne();
        await teardownWidget(tester, container);
      },
    );

    testWidgets('メール未認証画面からメール認証完了になった時、自動で HomeScreen に遷移すること', (
      tester,
    ) async {
      when(() => mockUser.emailVerified).thenReturn(false);

      final container = createContainer(isLoggedIn: true, useFirebase: true);

      await tester.pumpWidget(createTestWidget(tester, container));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      check(find.byType(FirebaseEmailVerificationScreen)).findsOne();

      final verifiedUser = MockUser();
      when(() => verifiedUser.uid).thenReturn('dummy_uid_123');
      when(() => verifiedUser.emailVerified).thenReturn(true);
      when(() => verifiedUser.isAnonymous).thenReturn(false);
      when(() => verifiedUser.email).thenReturn('test@example.com');
      when(() => verifiedUser.displayName).thenReturn('Test User');
      when(() => verifiedUser.phoneNumber).thenReturn(null);
      when(() => verifiedUser.photoURL).thenReturn(null);
      when(() => verifiedUser.tenantId).thenReturn(null);
      when(() => verifiedUser.refreshToken).thenReturn('dummy_token');

      (container.read(firebaseAuthStateProvider.notifier)
              as _FakeFirebaseAuthStateNotifier)
          .changeState(verifiedUser);

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      check(find.byType(HomeScreen)).findsOne();
      await teardownWidget(tester, container);
    });

    testWidgets('ログイン状態からログアウトした時、自動で FirebaseLoginScreen に戻ること', (
      tester,
    ) async {
      final container = createContainer(isLoggedIn: true, useFirebase: true);

      await tester.pumpWidget(createTestWidget(tester, container));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      check(find.byType(HomeScreen)).findsOne();

      (container.read(firebaseAuthStateProvider.notifier)
              as _FakeFirebaseAuthStateNotifier)
          .changeState(null);

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      check(find.byType(FirebaseLoginScreen)).findsOne();
      await teardownWidget(tester, container);
    });
  });

  group('RouteData ユニットテスト', () {
    testWidgets('LoginRoute.build: 直接 build メソッドを呼んだ時に正しいWidgetを返すこと', (
      tester,
    ) async {
      // 画面サイズを固定し、テスト終了時にリセットする
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
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
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: testLocalizations,
            supportedLocales: const [Locale('ja')],
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  const route = LoginRoute();
                  return route.build(context, MockGoRouterState());
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      check(find.byType(FirebaseLoginScreen)).findsOne();

      await teardownWidget(tester, container);
    });

    test('HomeRoute.build: HomeScreen を返すこと', () {
      final widget = const HomeRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      check(widget).isA<HomeScreen>();
    });

    test('SettingsRoute.build: SettingsScreen を返すこと', () {
      final widget = const SettingsRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      check(widget).isA<SettingsScreen>();
    });

    test('UserListRoute.build: UserListScreen を返すこと', () {
      final widget = const UserListRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      check(widget).isA<UserListScreen>();
    });

    test('ChatRoute.build: ChatScreen を返すこと', () {
      final widget = const ChatRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      check(widget).isA<ChatScreen>();
    });

    test('ChartInputRoute.build: ChartInputScreen を返すこと', () {
      final widget = const ChartInputRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      check(widget).isA<ChartInputScreen>();
    });

    test('ChartDisplayRoute.build: ChartDisplayScreen を返すこと', () {
      final widget = const ChartDisplayRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      check(widget).isA<ChartDisplayScreen>();
    });

    test('MemosRoute.build: MemoScreen を返すこと', () {
      final widget = const MemosRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      check(widget).isA<MemoScreen>();
    });

    test('SplashRoute.build: SplashScreen を返すこと', () {
      final widget = const SplashRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      check(widget).isA<SplashScreen>();
    });

    test('SignUpRoute.build: FirebaseSignUpScreen を返すこと', () {
      final widget = const SignUpRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      check(widget).isA<FirebaseSignUpScreen>();
    });

    test('ResetPasswordRoute.build: FirebaseResetPasswordScreen を返すこと', () {
      final widget = const ResetPasswordRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      check(widget).isA<FirebaseResetPasswordScreen>();
    });

    test(
      'EmailVerificationRoute.build: FirebaseEmailVerificationScreen を返すこと',
      () {
        final widget = const EmailVerificationRoute().build(
          MockBuildContext(),
          MockGoRouterState(),
        );
        check(widget).isA<FirebaseEmailVerificationScreen>();
      },
    );

    test('AppShellRouteData.builder: MainShellScreen を返すこと', () {
      final mockShell = MockStatefulNavigationShell();
      final widget = const AppShellRouteData().builder(
        MockBuildContext(),
        MockGoRouterState(),
        mockShell,
      );
      check(widget).isA<MainShellScreen>();
    });

    test('HomeBranch: インスタンス化できること', () {
      check(HomeBranch()).isNotNull();
    });

    test('ChatBranch: インスタンス化できること', () {
      check(ChatBranch()).isNotNull();
    });

    test('MemosBranch: インスタンス化できること', () {
      check(MemosBranch()).isNotNull();
    });

    test('ChartBranch: インスタンス化できること', () {
      check(ChartBranch()).isNotNull();
    });

    test('UserBranch: インスタンス化できること', () {
      check(UserBranch()).isNotNull();
    });
  });

  group('TypedRouteAnalyticsObserver テスト', () {
    test('didPush: 画面遷移時に Analytics にログが送信されること', () async {
      final observer = TypedRouteAnalyticsObserver(
        analytics: mockAnalytics,
        talker: mockTalker,
      );
      final route = MaterialPageRoute<void>(
        builder: (_) => const SizedBox(),
        settings: const RouteSettings(name: 'TestScreen'),
      );
      observer.didPush(route, null);
      verify(
        () => mockAnalytics.logScreenView(
          screenClass: 'TestScreen',
          screenName: 'TestScreen',
        ),
      ).called(1);
    });

    test('didReplace: 画面置換時に Analytics にログが送信されること', () {
      final observer = TypedRouteAnalyticsObserver(
        analytics: mockAnalytics,
        talker: mockTalker,
      );
      final route = MaterialPageRoute<void>(
        builder: (_) => const SizedBox(),
        settings: const RouteSettings(name: 'TargetRoute'),
      );
      observer.didReplace(newRoute: route);
      verify(
        () => mockAnalytics.logScreenView(
          screenClass: 'TargetRoute',
          screenName: 'TargetRoute',
        ),
      ).called(1);
    });

    test('didPop: 画面を戻った時に Analytics に前の画面のログが送信されること', () {
      final observer = TypedRouteAnalyticsObserver(
        analytics: mockAnalytics,
        talker: mockTalker,
      );
      final previousRoute = MaterialPageRoute<void>(
        builder: (_) => const SizedBox(),
        settings: const RouteSettings(name: 'PreviousScreen'),
      );
      final currentRoute = MaterialPageRoute<void>(
        builder: (_) => const SizedBox(),
        settings: const RouteSettings(name: 'CurrentScreen'),
      );

      observer.didPop(currentRoute, previousRoute);
      verify(
        () => mockAnalytics.logScreenView(
          screenClass: 'PreviousScreen',
          screenName: 'PreviousScreen',
        ),
      ).called(1);
    });

    testWidgets('オンボーディング未完了の時、OnboardingScreenが表示されること', (tester) async {
      final container = createContainer(
        isLoggedIn: false,
        useFirebase: false,
        isOnboardingCompleted: false,
      );

      await tester.pumpWidget(createTestWidget(tester, container));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      check(find.byType(OnboardingScreen)).findsOne();
      await teardownWidget(tester, container);
    });

    testWidgets('オンボーディング画面で完了操作（はじめる）を行うと、ログイン画面へ自動で遷移すること', (tester) async {
      final container = createContainer(
        isLoggedIn: false,
        useFirebase: false,
        isOnboardingCompleted: false,
      );

      await tester.pumpWidget(createTestWidget(tester, container));
      await tester.pumpAndSettle();

      check(find.byType(OnboardingScreen)).findsOne();

      // 「次へ」をタップして3ページ目へ進む
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();

      // 「はじめる」をタップしてオンボーディングを完了させる
      await tester.tap(find.text('はじめる'));
      await tester.pumpAndSettle();

      // onboardingProvider の変更によりルーターが再評価され、LoginScreenに遷移することを確認
      check(find.byType(LoginScreen)).findsOne();

      await teardownWidget(tester, container);
    });
  });

  group('MainShellScreen Widgetテスト', () {
    testWidgets('ボトムナビゲーションバーが正しく描画され、タブをタップすると各画面に遷移すること', (
      tester,
    ) async {
      final container = createContainer(isLoggedIn: true, useFirebase: true);

      await tester.pumpWidget(createTestWidget(tester, container));
      await tester.pumpAndSettle();

      // 初期表示は HomeScreen が表示されていること
      check(find.byType(MainShellScreen)).findsOne();
      check(find.byType(HomeScreen)).findsOne();

      // 各タブが表示されていることの確認（NavigationBar内のテキストを検索）
      check(find.byType(NavigationBar)).findsOne();
      final navBar = find.byType(NavigationBar);
      check(find.descendant(of: navBar, matching: find.text('ホーム'))).findsOne();
      check(
        find.descendant(of: navBar, matching: find.text('チャット')),
      ).findsOne();
      check(find.descendant(of: navBar, matching: find.text('メモ'))).findsOne();
      check(find.descendant(of: navBar, matching: find.text('グラフ'))).findsOne();
      check(
        find.descendant(of: navBar, matching: find.text('ユーザー')),
      ).findsOne();

      // チャットタブ（インデックス1）をタップする
      await tester.tap(
        find.descendant(of: navBar, matching: find.text('チャット')),
      );
      await tester.pumpAndSettle();

      // ChatScreen に切り替わっていることを確認
      check(find.byType(ChatScreen)).findsOne();

      // 同じチャットタブを再度タップする（initialLocation: true の分岐をテストするため）
      await tester.tap(
        find.descendant(of: navBar, matching: find.text('チャット')),
      );
      await tester.pumpAndSettle();

      // メモタブ（インデックス2）をタップする
      await tester.tap(find.descendant(of: navBar, matching: find.text('メモ')));
      await tester.pumpAndSettle();

      // MemoScreen に切り替わっていることを確認
      check(find.byType(MemoScreen)).findsOne();

      await teardownWidget(tester, container);
    });
  });
}
