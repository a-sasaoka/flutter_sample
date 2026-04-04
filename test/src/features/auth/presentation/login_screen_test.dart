import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/presentation/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モック＆Fakeクラスの定義 ---

class FakeAuthStateNotifier extends AuthStateNotifier {
  FakeAuthStateNotifier({required this.onLogin});
  final Future<void> Function(String, String) onLogin;

  @override
  Future<void> login(String accessToken, String refreshToken) async {
    await onLogin(accessToken, refreshToken);
  }
}

class MockAnalyticsService extends Mock implements AnalyticsService {}

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

void main() {
  late MockAnalyticsService mockAnalyticsService;
  late MockAppLocalizations mockL10n;

  // FakeNotifierの挙動をテストごとにコントロールするための変数
  late Future<void> Function(String, String) mockLoginAction;
  late int loginCallCount;

  setUpAll(() {
    registerFallbackValue(AnalyticsEvent.loginSuccess);
  });

  setUp(() {
    mockAnalyticsService = MockAnalyticsService();
    mockL10n = MockAppLocalizations();

    // 毎テストの初期化
    loginCallCount = 0;
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

    when(() => mockL10n.errorDialogTitle).thenReturn('エラーが発生しました');
    when(() => mockL10n.errorUnknown).thenReturn('予期しないエラーが発生しました');
    when(() => mockL10n.ok).thenReturn('OK');
    when(() => mockL10n.close).thenReturn('閉じる');
  });

  Widget createTestWidget() {
    // context.pop() が動くように GoRouter を設定
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        // Fakeクラスに、テストごとに変えられる処理(mockLoginAction)を渡す
        authStateProvider.overrideWith(
          () => FakeAuthStateNotifier(onLogin: (a, b) => mockLoginAction(a, b)),
        ),
        analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
      ],
      // MaterialApp.router に変更
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
      ),
    );
  }

  group('LoginScreen (API)', () {
    testWidgets('UIが正しくレンダリングされること', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ログイン'), findsOneWidget);
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.text('ログインする'), findsOneWidget);
    });

    testWidgets('未入力でボタンを押した場合は何も起きないこと(バリデーション)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('ログインする'));
      await tester.pumpAndSettle();

      // Fakeのメソッドが呼ばれていないことと、Analyticsが呼ばれていないことを確認
      expect(loginCallCount, 0);
      verifyZeroInteractions(mockAnalyticsService);
    });

    testWidgets('ログイン処理中、ローディング表示になり入力がロックされること', (tester) async {
      // 遅延を発生させてローディング中を検証
      mockLoginAction = (a, b) async =>
          Future.delayed(const Duration(milliseconds: 100));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      await tester.tap(find.text('ログインする'));

      // ポンプして画面を再描画
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('ログイン成功時、SnackBarが表示され、Analyticsにログが送信されること', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      await tester.tap(find.text('ログインする'));

      await tester.pump();

      // Fakeメソッドが呼ばれたか
      expect(loginCallCount, 1);

      // Analyticsが呼ばれたか
      verify(
        () => mockAnalyticsService.logEvent(event: AnalyticsEvent.loginSuccess),
      ).called(1);

      expect(find.byType(SnackBar), findsWidgets);
      expect(find.text('ログイン成功！'), findsWidgets);

      await tester.pumpAndSettle();
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

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('エラーが発生しました'), findsOneWidget);
      expect(find.text('予期しないエラーが発生しました'), findsOneWidget);

      // ダイアログのOKボタンを押して閉じる
      await tester.tap(find.text('OK'));

      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
