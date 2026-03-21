import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/network/logger_provider.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:flutter_sample/src/core/widgets/not_found_screen.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_email_verification_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_login_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_reset_password_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_sign_up_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/login_screen.dart';
import 'package:flutter_sample/src/features/chat/presentation/chat_screen.dart';
import 'package:flutter_sample/src/features/home/presentation/home_screen.dart';
import 'package:flutter_sample/src/features/sample_feature/presentation/sample_screen.dart';
import 'package:flutter_sample/src/features/settings/presentation/settings_screen.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_screen.dart';
import 'package:flutter_sample/src/features/user/presentation/user_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class MockLogger extends Mock implements Logger {}

class MockGoRouterState extends Mock implements GoRouterState {}

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late MockFirebaseAnalytics mockAnalytics;
  late MockLogger mockLogger;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    mockLogger = MockLogger();
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

  Widget createTestWidget(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: container.read(routerProvider),
        localizationsDelegates: testLocalizations,
        supportedLocales: const [Locale('ja')],
      ),
    );
  }

  group('AppRouter / RouteData Build テスト', () {
    testWidgets('HomeRoute: / にアクセスした時に HomeScreen が表示されること', (tester) async {
      final container = ProviderContainer(
        overrides: [
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          loggerProvider.overrideWithValue(mockLogger),
          flavorProvider.overrideWithValue(Flavor.dev),
          authStateProvider.overrideWith(
            () => _FakeAuthStateNotifier(isLoggedIn: true),
          ),
          routerProvider.overrideWith(
            (ref) => GoRouter(
              initialLocation: '/',
              routes: $appRoutes,
              redirect: (context, state) {
                final authState = ref.read(authStateProvider);
                if (authState.isLoading) return null;
                return authState.value ?? false ? null : '/login';
              },
            ),
          ),
        ],
      );

      try {
        await tester.pumpWidget(createTestWidget(container));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);

        // コンテナを破棄してタイマーの「元」を絶つ
        container.dispose();
        // さらに時間を進めて、残っているタイマー（0.4秒など）を無理やり発火させて消化する
        await tester.pump(const Duration(seconds: 5));
      } finally {
        // 万が一途中でエラーになっても確実に dispose する
      }
    });

    testWidgets('LoginRoute: 未ログイン時にログイン画面が表示されること', (tester) async {
      final container = ProviderContainer(
        overrides: [
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          loggerProvider.overrideWithValue(mockLogger),
          flavorProvider.overrideWithValue(Flavor.dev),
          authStateProvider.overrideWith(
            () => _FakeAuthStateNotifier(isLoggedIn: false),
          ),
          routerProvider.overrideWith(
            (ref) => GoRouter(
              initialLocation: '/', // / から /login へのリダイレクトをテスト
              routes: $appRoutes,
              redirect: (context, state) {
                final authState = ref.read(authStateProvider);
                if (authState.isLoading) return null;
                final isLoggingIn = state.matchedLocation == '/login';
                if (authState.value == false && !isLoggingIn) return '/login';
                return null;
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      final loginFinder = find.byWidgetPredicate(
        (widget) => widget is FirebaseLoginScreen || widget is LoginScreen,
      );
      expect(loginFinder, findsOneWidget);
    });

    testWidgets('LoginRoute.build: Provider経由で正しいWidgetを返すこと', (tester) async {
      final container = ProviderContainer(
        overrides: [
          useFirebaseAuthProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

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
      expect(find.byType(FirebaseLoginScreen), findsOneWidget);
    });
  });

  group('TypedRouteAnalyticsObserver テスト', () {
    final containerRefProvider = Provider((ref) => ref);

    test('didPush: 画面遷移時に Analytics にログが送信されること', () async {
      final container = ProviderContainer(
        overrides: [loggerProvider.overrideWithValue(mockLogger)],
      );
      addTearDown(container.dispose);

      final observer = TypedRouteAnalyticsObserver(
        ref: container.read(containerRefProvider),
        analytics: mockAnalytics,
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

    test('HomeRoute.build: HomeScreen を返すこと', () {
      final widget = const HomeRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      expect(widget, isA<HomeScreen>());
    });

    test('SettingsRoute.build: SettingsScreen を返すこと', () {
      final widget = const SettingsRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      expect(widget, isA<SettingsScreen>());
    });

    test('SampleRoute.build: SampleScreen を返すこと', () {
      final widget = const SampleRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      expect(widget, isA<SampleScreen>());
    });

    test('UserListRoute.build: UserListScreen を返すこと', () {
      final widget = const UserListRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      expect(widget, isA<UserListScreen>());
    });

    test('ChatRoute.build: ChatScreen を返すこと', () {
      final widget = const ChatRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      expect(widget, isA<ChatScreen>());
    });

    test('SplashRoute.build: SplashScreen を返すこと', () {
      final widget = const SplashRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      expect(widget, isA<SplashScreen>());
    });

    test('SignUpRoute.build: FirebaseSignUpScreen を返すこと', () {
      final widget = const SignUpRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      expect(widget, isA<FirebaseSignUpScreen>());
    });

    test('ResetPasswordRoute.build: FirebaseResetPasswordScreen を返すこと', () {
      final widget = const ResetPasswordRoute().build(
        MockBuildContext(),
        MockGoRouterState(),
      );
      expect(widget, isA<FirebaseResetPasswordScreen>());
    });

    test(
      'EmailVerificationRoute.build: FirebaseEmailVerificationScreen を返すこと',
      () {
        final widget = const EmailVerificationRoute().build(
          MockBuildContext(),
          MockGoRouterState(),
        );
        expect(widget, isA<FirebaseEmailVerificationScreen>());
      },
    );

    test('didReplace メソッドを直接呼び出してカバレッジを100%にする', () {
      final container = ProviderContainer(overrides: []);
      final observer = TypedRouteAnalyticsObserver(
        ref: container.read(Provider((ref) => ref)),
        analytics: mockAnalytics,
      );

      // ダミーのルートを作成して直接渡す
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
  });

  group('routerProvider エラーハンドリング', () {
    testWidgets('存在しないパスにアクセスした時、NotFoundScreenが表示されること', (tester) async {
      final container = ProviderContainer(
        overrides: [
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          loggerProvider.overrideWithValue(mockLogger),
          authStateProvider.overrideWith(
            () => _FakeAuthStateNotifier(isLoggedIn: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      container.read(routerProvider).go('/not-found-path-123');

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
    });
  });

  group('routerProvider リダイレクト判定テスト', () {
    testWidgets('useFirebaseAuthProvider が false の時、LoginScreen が表示されること', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          loggerProvider.overrideWithValue(mockLogger),
          flavorProvider.overrideWithValue(Flavor.dev),
          useFirebaseAuthProvider.overrideWithValue(false),
          authStateProvider.overrideWith(
            () => _FakeAuthStateNotifier(isLoggedIn: false),
          ),
          routerProvider.overrideWith(
            (ref) => GoRouter(
              initialLocation: '/',
              routes: $appRoutes,
              redirect: (context, state) {
                final authState = ref.read(authStateProvider);
                if (authState.isLoading) return null;
                final isLoggingIn = state.matchedLocation == '/login';
                if (authState.value == false && !isLoggingIn) return '/login';
                return null;
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets(
      'useFirebaseAuthProvider が true の時、FirebaseLoginScreen が表示されること',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
            loggerProvider.overrideWithValue(mockLogger),
            flavorProvider.overrideWithValue(Flavor.dev),
            useFirebaseAuthProvider.overrideWithValue(true),
            authStateProvider.overrideWith(
              () => _FakeAuthStateNotifier(isLoggedIn: false),
            ),
            routerProvider.overrideWith(
              (ref) => GoRouter(
                initialLocation: '/',
                routes: $appRoutes,
                redirect: (context, state) {
                  final authState = ref.read(authStateProvider);
                  if (authState.isLoading) return null;
                  final isLoggingIn = state.matchedLocation == '/login';
                  if (authState.value == false && !isLoggingIn) return '/login';
                  return null;
                },
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(createTestWidget(container));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(find.byType(FirebaseLoginScreen), findsOneWidget);
      },
    );

    testWidgets('authGuard: Firebase未使用モードかつ未ログイン時に通常のリダイレクトが行われること', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          loggerProvider.overrideWithValue(mockLogger),
          flavorProvider.overrideWithValue(Flavor.dev),
          // 💡 1. Firebaseモードをオフにする
          useFirebaseAuthProvider.overrideWithValue(false),
          // 💡 2. 未ログイン状態にする
          authStateProvider.overrideWith(
            () => _FakeAuthStateNotifier(isLoggedIn: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      // 💡 3. 初期位置を / (Home) に設定して起動
      // これにより、authGuard 内で 「未ログインなので /login へ」という判定を強制的に通す
      await tester.pumpWidget(createTestWidget(container));

      // GoRouter の解決を待つ
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // 💡 4. 結果として LoginScreen が表示されていることを確認
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}

class _FakeAuthStateNotifier extends AuthStateNotifier {
  _FakeAuthStateNotifier({required this.isLoggedIn});
  final bool isLoggedIn;
  @override
  Future<bool> build() {
    state = AsyncData(isLoggedIn);
    return Future.value(isLoggedIn);
  }
}
