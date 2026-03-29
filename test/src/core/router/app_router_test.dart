import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
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

class MockUser extends Mock implements User {}

class _FakeAuthStateNotifier extends AuthStateNotifier {
  _FakeAuthStateNotifier({required this.isLoggedIn});
  final bool isLoggedIn;
  @override
  Future<bool> build() async => isLoggedIn;

  // 外部から状態を強制的に変更するメソッド
  void changeState({required bool value}) {
    state = AsyncData(value);
  }
}

class _FakeFirebaseAuthStateNotifier extends FirebaseAuthStateNotifier {
  _FakeFirebaseAuthStateNotifier({required this.isLoggedIn, this.mockUser});
  final bool isLoggedIn;
  final User? mockUser;
  @override
  User? build() => isLoggedIn ? mockUser : null;

  // 外部からFirebaseのログイン状態を強制的に変更するメソッド
  // ignore: use_setters_to_change_properties
  void changeState(User? user) {
    state = user;
  }
}

void main() {
  late MockFirebaseAnalytics mockAnalytics;
  late MockLogger mockLogger;
  late MockUser mockUser;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    mockLogger = MockLogger();
    mockUser = MockUser();

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
  }) {
    final container = ProviderContainer(
      overrides: [
        firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
        loggerProvider.overrideWithValue(mockLogger),
        flavorProvider.overrideWithValue(Flavor.dev),
        useFirebaseAuthProvider.overrideWithValue(useFirebase),
        authStateProvider.overrideWith(
          () => _FakeAuthStateNotifier(isLoggedIn: isLoggedIn),
        ),
        firebaseAuthStateProvider.overrideWith(
          () => _FakeFirebaseAuthStateNotifier(
            isLoggedIn: isLoggedIn,
            mockUser: mockUser,
          ),
        ),
      ],
    )..listen(routerProvider, (_, _) {});
    return container;
  }

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

      await tester.pumpWidget(createTestWidget(container));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(HomeScreen), findsOneWidget);
      await teardownWidget(tester, container);
    });

    testWidgets('未ログインかつ Firebase 未使用の時、通常 LoginScreen が表示されること', (
      tester,
    ) async {
      final container = createContainer(isLoggedIn: false, useFirebase: false);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(LoginScreen), findsOneWidget);
      await teardownWidget(tester, container);
    });

    testWidgets('未ログインかつ Firebase 使用の時、FirebaseLoginScreen が表示されること', (
      tester,
    ) async {
      final container = createContainer(isLoggedIn: false, useFirebase: true);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(FirebaseLoginScreen), findsOneWidget);
      await teardownWidget(tester, container);
    });

    testWidgets('存在しないパスにアクセスした時、NotFoundScreenが表示されること', (tester) async {
      final container = createContainer(isLoggedIn: true, useFirebase: false);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      container.read(routerProvider).go('/not-found-path-123');

      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(NotFoundScreen), findsOneWidget);
      await teardownWidget(tester, container);
    });

    testWidgets('認証状態の変更を検知してルーターが更新（Listen）されること', (tester) async {
      final container = createContainer(isLoggedIn: false, useFirebase: true);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      // authStateProvider の状態を強制的に変更する
      (container.read(authStateProvider.notifier) as _FakeAuthStateNotifier)
          .changeState(value: true);
      await tester.pump();

      // firebaseAuthStateProvider の状態を強制的に変更する
      (container.read(firebaseAuthStateProvider.notifier)
              as _FakeFirebaseAuthStateNotifier)
          .changeState(mockUser);
      await tester.pump();

      // エラーが起きず正常に動作していればOK
      expect(tester.takeException(), isNull);
      await teardownWidget(tester, container);
    });
  });

  group('RouteData ユニットテスト', () {
    testWidgets('LoginRoute.build: 直接 build メソッドを呼んだ時に正しいWidgetを返すこと', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [useFirebaseAuthProvider.overrideWithValue(true)],
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
      expect(find.byType(FirebaseLoginScreen), findsOneWidget);

      await teardownWidget(tester, container);
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
  });

  group('TypedRouteAnalyticsObserver テスト', () {
    test('didPush: 画面遷移時に Analytics にログが送信されること', () async {
      final observer = TypedRouteAnalyticsObserver(
        analytics: mockAnalytics,
        logger: mockLogger,
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
        logger: mockLogger,
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
  });
}
