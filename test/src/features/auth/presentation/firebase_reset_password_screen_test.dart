// ignore_for_file: prefer_const_constructors, document_ignores
import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_reset_password_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モッククラスの定義 ---

class MockFirebaseAuthRepository extends Mock
    implements FirebaseAuthRepository {}

class MockAppLocalizations extends Mock implements AppLocalizations {}

class MockLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const MockLocalizationsDelegate(this.mock);
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
  late MockFirebaseAuthRepository mockAuthRepo;
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockAuthRepo = MockFirebaseAuthRepository();
    mockL10n = MockAppLocalizations();

    // 多言語化のスタブ
    when(() => mockL10n.resetPassword).thenReturn('パスワード再設定');
    when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
    when(() => mockL10n.send).thenReturn('送信する');
    when(() => mockL10n.resetPasswordMailSent).thenReturn('再設定メールを送信しました');

    // 💡 ErrorHandler と SnackBar 内部で使用するスタブ
    when(() => mockL10n.errorUnknown).thenReturn('予期しないエラーが発生しました');
    when(() => mockL10n.close).thenReturn('閉じる');
  });

  /// テスト用のWidgetを構築するヘルパー
  Widget createTestWidget() {
    final router = GoRouter(
      // 💡 pop() のテストをするため、ダミーのホーム画面(/)から遷移する構成にする
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push('/reset'),
              child: const Text('Go Reset'),
            ),
          ),
        ),
        GoRoute(
          path: '/reset',
          builder: (context, state) => FirebaseResetPasswordScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: [MockLocalizationsDelegate(mockL10n)],
      ),
    );
  }

  // 画面をセットアップし、ResetPassword画面まで進めるヘルパー関数
  Future<void> navigateToResetScreen(WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go Reset'));
    await tester.pumpAndSettle();
  }

  group('FirebaseResetPasswordScreen', () {
    testWidgets('UIが正しくレンダリングされること', (tester) async {
      await navigateToResetScreen(tester);

      check(find.widgetWithText(AppBar, 'パスワード再設定')).findsOne();
      check(find.text('メールアドレス')).findsOne();
      check(find.text('送信する')).findsOne();
    });

    testWidgets('未入力でボタンを押した場合は何も起きないこと(バリデーション)', (tester) async {
      await navigateToResetScreen(tester);

      // 未入力のままボタンを押す
      await tester.tap(find.text('送信する'));
      await tester.pumpAndSettle();

      // Repository のメソッドが呼ばれていないことを確認
      verifyNever(() => mockAuthRepo.sendPasswordResetEmail(any()));
    });

    testWidgets('送信処理中、ローディング表示になり入力がロックされること', (tester) async {
      // 💡 処理完了までに時間をかけることでローディング中を検証
      when(
        () => mockAuthRepo.sendPasswordResetEmail(any()),
      ).thenAnswer(
        (_) async => Future.delayed(const Duration(milliseconds: 100)),
      );

      await navigateToResetScreen(tester);

      // メールアドレスを入力
      await tester.enterText(find.byType(TextField), 'test@example.com');

      // 送信ボタンをタップ
      await tester.tap(find.text('送信する'));

      // 💡 ポンプして画面を再描画（処理はまだ終わっていない）
      await tester.pump();

      // インジケーターが表示されていること
      check(find.byType(CircularProgressIndicator)).findsOne();

      // 非同期処理を完了させる
      await tester.pumpAndSettle();

      // ローディングが終了していること
      check(find.byType(CircularProgressIndicator)).findsNothing();
    });

    testWidgets('送信成功時、SnackBarが表示され、前の画面に pop() されること', (tester) async {
      when(
        () => mockAuthRepo.sendPasswordResetEmail('test@example.com'),
      ).thenAnswer((_) async {});

      await navigateToResetScreen(tester);

      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.tap(find.text('送信する'));

      // アニメーションを1フレーム進めて SnackBar を描画
      await tester.pump();

      // Repositoryが呼ばれたか検証
      verify(
        () => mockAuthRepo.sendPasswordResetEmail('test@example.com'),
      ).called(1);

      // SnackBar が表示されているか検証
      check(find.byType(SnackBar)).findsAny();
      check(find.text('再設定メールを送信しました')).findsAny();

      // アニメーションを最後まで完了させる (pop の画面遷移を含む)
      await tester.pumpAndSettle();

      // 💡 元のダミーホーム画面に戻っていること（= popが成功していること）を確認
      check(find.text('Go Reset')).findsOne();
      check(find.widgetWithText(AppBar, 'パスワード再設定')).findsNothing();
    });

    testWidgets('送信失敗時(Exception発生時)、汎用のエラーSnackBarが表示されること', (tester) async {
      when(
        () => mockAuthRepo.sendPasswordResetEmail(any()),
      ).thenThrow(Exception('Send Error'));

      await navigateToResetScreen(tester);

      await tester.enterText(find.byType(TextField), 'error@example.com');
      await tester.tap(find.text('送信する'));

      await tester.pump(); // SnackBar描画のために1フレーム進める

      // 💡 ErrorHandler によって「予期しないエラー」の SnackBar が出ること
      check(find.byType(SnackBar)).findsOne();
      check(find.text('予期しないエラーが発生しました')).findsOne();

      // エラー時は画面が pop されず残っていることを確認
      check(find.widgetWithText(AppBar, 'パスワード再設定')).findsOne();
    });

    testWidgets('画面外タップでキーボードが閉じること', (tester) async {
      await navigateToResetScreen(tester);

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
  });
}
