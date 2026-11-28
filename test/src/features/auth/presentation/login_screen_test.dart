// ignore_for_file: prefer_const_constructors, document_ignores
import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/features/auth/application/account_deletion_notice_notifier.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/presentation/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../core/widgets/widgets_test_helper.dart';

// --- モック＆Fakeクラスの定義 ---

class FakeAuthStateNotifier extends AuthStateNotifier {
  FakeAuthStateNotifier({required this.onLogin, this.loginResult = true});
  final Future<void> Function(String, String) onLogin;
  final bool loginResult;

  @override
  Future<bool> build() async => false;

  @override
  Future<bool> login(String accessToken, String refreshToken) async {
    await onLogin(accessToken, refreshToken);
    return loginResult;
  }

  @override
  Future<bool> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    await onLogin(email, password);
    if (loginResult) {
      state = const AsyncData(true);
    }
    return loginResult;
  }
}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockAnalyticsService mockAnalyticsService;
  late MockAppLocalizations mockL10n;

  // FakeNotifierの挙動をテストごとにコントロールするための変数
  late Future<void> Function(String, String) mockLoginAction;
  late int loginCallCount;
  late bool mockLoginResult;

  setUpAll(() {
    registerFallbackValue(AnalyticsEvent.loginSuccess);
  });

  setUp(() {
    mockAnalyticsService = MockAnalyticsService();
    mockL10n = MockAppLocalizations();

    // 毎テストの初期化
    loginCallCount = 0;
    mockLoginResult = true;
    mockLoginAction = (a, b) async {
      loginCallCount++;
    };

    when(
      () => mockAnalyticsService.logEvent(event: AnalyticsEvent.loginSuccess),
    ).thenAnswer((_) async {});

    when(() => mockL10n.loginTitle).thenReturn('ログイン');
    when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
    when(() => mockL10n.loginPasswordLabel).thenReturn('パスワード');
    when(() => mockL10n.loginButton).thenReturn('ログインする');
    when(() => mockL10n.loginSuccess).thenReturn('ログイン成功！');
    when(() => mockL10n.accountDeletionCompleted).thenReturn('アカウントを削除しました');

    when(() => mockL10n.errorDialogTitle).thenReturn('エラーが発生しました');
    when(() => mockL10n.errorUnknown).thenReturn('予期しないエラーが発生しました');
    when(() => mockL10n.ok).thenReturn('OK');
    when(() => mockL10n.close).thenReturn('閉じる');
    when(() => mockL10n.semanticsEmailInput).thenReturn('メールアドレス入力欄');
    when(() => mockL10n.semanticsPasswordInput).thenReturn('パスワード入力欄');
    when(() => mockL10n.semanticsLoginButton).thenReturn('ログイン実行ボタン');

    // バリデーションメッセージのスタブ設定
    when(() => mockL10n.validationEmailRequired).thenReturn('メールアドレスを入力してください');
    when(
      () => mockL10n.validationNotOnlyWhitespace,
    ).thenReturn('空白のみの入力はできません');
    when(
      () => mockL10n.validationEmailInvalid,
    ).thenReturn('正しいメールアドレス形式で入力してください');
    when(
      () => mockL10n.validationPasswordRequired,
    ).thenReturn('パスワードを入力してください');
    when(() => mockL10n.validationPasswordMinLength(any())).thenAnswer(
      (invocation) => 'パスワードは${invocation.positionalArguments[0]}文字以上で入力してください',
    );
  });

  Widget createTestWidget() {
    // context.pop() が動くように GoRouter を設定
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
      ],
    );

    return ProviderScope(
      overrides: [
        // Fakeクラスに、テストごとに変えられる処理(mockLoginAction)を渡す
        authStateProvider.overrideWith(
          () => FakeAuthStateNotifier(
            onLogin: (a, b) => mockLoginAction(a, b),
            loginResult: mockLoginResult,
          ),
        ),
        analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
      ],
      // MaterialApp.router に変更
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: [MockLocalizationsDelegate(mockL10n)],
      ),
    );
  }

  group('LoginScreen (API)', () {
    test('コンストラクタでインスタンスが生成できること', () {
      final screen = LoginScreen();
      check(screen).isA<LoginScreen>();
    });

    testWidgets('UIが正しくレンダリングされること', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      check(find.widgetWithText(AppBar, 'ログイン')).findsOne();
      check(find.text('メールアドレス')).findsOne();
      check(find.text('パスワード')).findsOne();
      check(find.text('ログインする')).findsOne();
    });

    testWidgets('未入力でボタンを押した場合は何も起きず、必須エラーが表示されること', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('ログインする'));
      await tester.pumpAndSettle();

      // エラーメッセージが表示されていること
      check(find.text('メールアドレスを入力してください')).findsOne();
      check(find.text('パスワードを入力してください')).findsOne();

      // Fakeのメソッドが呼ばれていないことと、Analyticsが呼ばれていないことを確認
      check(loginCallCount).equals(0);
      verifyZeroInteractions(mockAnalyticsService);
    });

    testWidgets('空白文字のみを入力してボタンを押した場合は何も起きず、空白エラーが表示されること', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '   ');
      await tester.enterText(find.byType(TextField).at(1), '   ');

      await tester.tap(find.text('ログインする'));
      await tester.pumpAndSettle();

      check(find.text('空白のみの入力はできません')).findsExactly(2);
      check(loginCallCount).equals(0);
      verifyZeroInteractions(mockAnalyticsService);
    });

    testWidgets('不正なメール形式を入力した場合は何も起きず、メール形式エラーが表示されること', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'invalid-email');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      await tester.tap(find.text('ログインする'));
      await tester.pumpAndSettle();

      check(find.text('正しいメールアドレス形式で入力してください')).findsOne();
      check(loginCallCount).equals(0);
      verifyZeroInteractions(mockAnalyticsService);
    });

    testWidgets('6文字未満のパスワードを入力した場合は何も起きず、文字数エラーが表示されること', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), '12345');

      await tester.tap(find.text('ログインする'));
      await tester.pumpAndSettle();

      check(find.text('パスワードは6文字以上で入力してください')).findsOne();
      check(loginCallCount).equals(0);
      verifyZeroInteractions(mockAnalyticsService);
    });

    testWidgets('ログイン処理中、ローディング表示になり入力がロックされること', (tester) async {
      // 遅延を発生させてローディング中を検証
      mockLoginAction = (a, b) async =>
          await Future.delayed(const Duration(milliseconds: 100));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      await tester.tap(find.text('ログインする'));

      // ポンプして画面を再描画
      await tester.pump();

      check(find.byType(CircularProgressIndicator)).findsOne();

      await tester.pumpAndSettle();

      check(find.byType(CircularProgressIndicator)).findsNothing();
    });

    testWidgets('ログイン成功時、SnackBarが表示され、Analyticsにログが送信されること', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      await tester.tap(find.text('ログインする'));

      await tester.pump();

      // Fakeメソッドが呼ばれたか
      check(loginCallCount).equals(1);

      // Analyticsが呼ばれたか
      verify(
        () => mockAnalyticsService.logEvent(event: AnalyticsEvent.loginSuccess),
      ).called(1);

      check(find.byType(SnackBar)).findsAny();
      check(find.text('ログイン成功！')).findsAny();

      await tester.pumpAndSettle();
    });

    testWidgets('古いログイン応答が破棄(false)された場合、ホーム遷移・成功通知・エラー表示を行わずログイン画面に留まること', (
      tester,
    ) async {
      mockLoginResult = false;
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            () => FakeAuthStateNotifier(
              onLogin: (a, b) => mockLoginAction(a, b),
              loginResult: mockLoginResult,
            ),
          ),
          analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
        ],
      );
      addTearDown(container.dispose);

      final routerListenable = ValueNotifier<bool>(false);
      addTearDown(routerListenable.dispose);
      container.listen(
        authStateProvider,
        (_, _) => routerListenable.value = !routerListenable.value,
      );

      final router = GoRouter(
        initialLocation: '/login',
        refreshListenable: routerListenable,
        redirect: (context, state) {
          final isLoggedIn = container.read(authStateProvider).value ?? false;
          if (isLoggedIn && state.uri.path == '/login') {
            return '/home';
          }
          return null;
        },
        routes: [
          GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
        ],
      );

      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: [MockLocalizationsDelegate(mockL10n)],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      final loginButton = find.text('ログインする');
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      check(loginCallCount).equals(1);
      check(container.read(authStateProvider).value).equals(false);
      check(find.text('Home')).findsNothing();
      check(find.text('ログインする')).findsOne();
      check(find.byType(CircularProgressIndicator)).findsNothing();
      check(find.byType(SnackBar)).findsNothing();
      check(find.byType(AlertDialog)).findsNothing();
      verifyZeroInteractions(mockAnalyticsService);
    });

    testWidgets('ログイン失敗時(Exception発生時)、エラーダイアログが表示されること', (tester) async {
      // 例外を発生させる
      mockLoginAction = (a, b) async {
        throw Exception('API Login Error');
      };

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'error@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      await tester.tap(find.text('ログインする'));

      // ダイアログの表示アニメーションだけを pump で進める
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      check(find.byType(AlertDialog)).findsOne();
      check(find.text('エラーが発生しました')).findsOne();
      check(find.text('予期しないエラーが発生しました')).findsOne();

      // ダイアログのOKボタンを押して閉じる
      await tester.tap(find.text('OK'));

      await tester.pumpAndSettle();

      check(find.byType(AlertDialog)).findsNothing();
    });

    testWidgets('画面外タップでキーボードが閉じること', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.tap(textFields.first);
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(textFields.first);
      check(FocusScope.of(context).focusedChild).isNotNull();

      // AppBarなど画面外をタップ
      await tester.tap(find.byType(AppBar));
      await tester.pumpAndSettle();

      check(FocusScope.of(context).focusedChild).isNull();
    });

    testWidgets('退会通知が completed の場合、画面表示後に完了SnackBarが表示され状態が消費されること', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            () =>
                FakeAuthStateNotifier(onLogin: (a, b) => mockLoginAction(a, b)),
          ),
          analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
        ],
      );
      addTearDown(container.dispose);
      container.read(accountDeletionNoticeProvider.notifier)
        ..reserve()
        ..confirmCompleted();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: [MockLocalizationsDelegate(mockL10n)],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      check(find.byType(SnackBar)).findsOne();
      check(find.text('アカウントを削除しました')).findsOne();
      check(
        container.read(accountDeletionNoticeProvider),
      ).equals(AccountDeletionNoticeStatus.none);
    });

    testWidgets('退会通知が reserved のみの場合、完了SnackBarは表示されず clear されても表示されないこと', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            () =>
                FakeAuthStateNotifier(onLogin: (a, b) => mockLoginAction(a, b)),
          ),
          analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(accountDeletionNoticeProvider.notifier)
        ..reserve();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: [MockLocalizationsDelegate(mockL10n)],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      check(find.byType(SnackBar)).findsNothing();
      check(
        container.read(accountDeletionNoticeProvider),
      ).equals(AccountDeletionNoticeStatus.reserved);

      // Auth削除失敗時に clear() されても完了SnackBarは表示されない
      notifier.clear();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      check(find.byType(SnackBar)).findsNothing();
      check(
        container.read(accountDeletionNoticeProvider),
      ).equals(AccountDeletionNoticeStatus.none);
    });

    testWidgets(
      'reserved 状態で先に画面がマウントされた後、confirmCompleted で確定すると完了SnackBarが1回だけ表示されること',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/login',
          routes: [
            GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(
              () => FakeAuthStateNotifier(
                onLogin: (a, b) => mockLoginAction(a, b),
              ),
            ),
            analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(accountDeletionNoticeProvider.notifier)
          ..reserve();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: [MockLocalizationsDelegate(mockL10n)],
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        check(find.byType(SnackBar)).findsNothing();

        notifier.confirmCompleted();
        check(tester.binding.hasScheduledFrame).isTrue();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        check(find.byType(SnackBar)).findsOne();
        check(find.text('アカウントを削除しました')).findsOne();
        check(
          container.read(accountDeletionNoticeProvider),
        ).equals(AccountDeletionNoticeStatus.none);
      },
    );
  });
}
