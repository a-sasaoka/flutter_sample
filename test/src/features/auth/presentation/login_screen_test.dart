import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/presentation/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モックとデリゲート ---
class MockAppLocalizations extends Mock implements AppLocalizations {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

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

// --- Fake Notifier ---
class FakeAuthStateNotifier extends AuthStateNotifier {
  bool shouldThrow = false;
  bool isLoginCalled = false;

  @override
  Future<bool> build() async => false;

  @override
  Future<void> login(String accessToken, String refreshToken) async {
    // 例外ルートのシミュレート用
    if (shouldThrow) {
      throw Exception('Dummy Exception');
    }
    isLoginCalled = true;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(AnalyticsEvent.loginSuccess);
  });

  late MockAppLocalizations mockL10n;
  late MockAnalyticsService mockAnalytics;

  setUp(() {
    mockL10n = MockAppLocalizations();
    mockAnalytics = MockAnalyticsService();

    // L10nのスタブ設定
    when(() => mockL10n.loginTitle).thenReturn('ログイン画面');
    when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
    when(() => mockL10n.loginPasswordLabel).thenReturn('パスワード');
    when(() => mockL10n.loginButton).thenReturn('ログイン');
    when(() => mockL10n.loginSuccess).thenReturn('ログインに成功しました');
    when(() => mockL10n.errorUnknown).thenReturn('予期せぬエラーが発生しました');
    when(() => mockL10n.errorDialogTitle).thenReturn('エラー');
    when(() => mockL10n.ok).thenReturn('OK');

    // AnalyticsServiceのスタブ設定 (Future<void> なので thenAnswer を使用)
    when(
      () => mockAnalytics.logEvent(event: any(named: 'event')),
    ).thenAnswer((_) async {});
  });

  /// テスト環境のセットアップヘルパー
  Future<void> setupWidget(
    WidgetTester tester,
    FakeAuthStateNotifier fakeNotifier,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // authStateProvider を Fake に差し替え
          authStateProvider.overrideWith(() => fakeNotifier),
          // analyticsServiceProvider を Mock に差し替え
          analyticsServiceProvider.overrideWithValue(mockAnalytics),
        ],
        child: MaterialApp(
          localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('LoginScreen', () {
    testWidgets('初期表示: 入力フォームとボタンが正しく表示されること', (tester) async {
      final fakeNotifier = FakeAuthStateNotifier();
      await setupWidget(tester, fakeNotifier);

      expect(find.text('ログイン画面'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'メールアドレス'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'パスワード'), findsOneWidget);
      expect(find.text('ログイン'), findsOneWidget);
    });

    testWidgets('正常系: ログイン成功時、SnackBarとAnalyticsイベント送信が実行されること', (
      tester,
    ) async {
      final fakeNotifier = FakeAuthStateNotifier();
      await setupWidget(tester, fakeNotifier);

      // Act: ログインボタンをタップ
      await tester.tap(find.text('ログイン'));

      // SnackBarのアニメーションを待つ
      await tester.pump();

      // Assert
      // 1. loginメソッドが呼ばれたか
      expect(fakeNotifier.isLoginCalled, isTrue);

      // 2. SnackBar が表示されたか
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('ログインに成功しました'), findsOneWidget);

      // 3. AnalyticsService.logEvent が正しい引数で呼ばれたか
      verify(
        () => mockAnalytics.logEvent(event: AnalyticsEvent.loginSuccess),
      ).called(1);
    });

    testWidgets('異常系: ログイン失敗時、ErrorHandler 経由でエラーダイアログが表示されること', (
      tester,
    ) async {
      // shouldThrow = true にして例外を発生させる
      final fakeNotifier = FakeAuthStateNotifier()..shouldThrow = true;
      await setupWidget(tester, fakeNotifier);

      // Act
      await tester.tap(find.text('ログイン'));

      // ダイアログのアニメーション完了を待つ
      await tester.pumpAndSettle();

      // Assert
      // 1. SnackBar は表示されていないこと
      expect(find.byType(SnackBar), findsNothing);

      // 2. Analyticsの送信は行われていないこと
      verifyNever(() => mockAnalytics.logEvent(event: any(named: 'event')));

      // 3. ダイアログが表示されていること
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}
