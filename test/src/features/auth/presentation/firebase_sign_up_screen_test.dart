// ignore_for_file: prefer_const_constructors, document_ignores
import 'package:checks/checks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_sign_up_screen.dart';
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
    when(() => mockL10n.signUpTitle).thenReturn('新規登録');
    when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
    when(() => mockL10n.loginPasswordLabel).thenReturn('パスワード');
    when(() => mockL10n.signUp).thenReturn('登録する');
    when(() => mockL10n.login).thenReturn('ログインへ戻る');
    when(() => mockL10n.emailVerificationTitle).thenReturn('メール認証');
    when(() => mockL10n.errorUnknown).thenReturn('予期しないエラーが発生しました');
    when(
      () => mockL10n.errorEmailAlreadyInUse,
    ).thenReturn('このメールアドレスは既に登録されています');
    when(() => mockL10n.close).thenReturn('閉じる');
  });

  /// テスト用のWidgetを構築するヘルパー
  Widget createTestWidget() {
    final router = GoRouter(
      initialLocation: '/signup',
      routes: [
        GoRoute(
          path: '/signup',
          builder: (context, state) => FirebaseSignUpScreen(),
        ),
      ],
      // 成功時に EmailVerificationRoute などへ遷移したことをキャッチする
      errorBuilder: (context, state) => Scaffold(
        body: Text('Navigated to ${state.uri}'),
      ),
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

  group('FirebaseSignUpScreen', () {
    testWidgets('UIが正しくレンダリングされること', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      check(find.widgetWithText(AppBar, '新規登録')).findsOne();
      check(find.text('メールアドレス')).findsOne();
      check(find.text('パスワード')).findsOne();
      check(find.text('登録する')).findsOne();
      check(find.text('ログインへ戻る')).findsOne();
    });

    testWidgets('未入力でボタンを押した場合は何も起きないこと(バリデーション)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 未入力のままボタンを押す
      await tester.tap(find.text('登録する'));
      await tester.pumpAndSettle();

      // Repository のメソッドが呼ばれていないことを確認
      verifyNever(() => mockAuthRepo.signUp(any(), any()));
      verifyNever(() => mockAuthRepo.sendEmailVerification());
    });

    testWidgets('入力値が Repository に渡され、成功時に確認メールを送信すること', (tester) async {
      when(
        () => mockAuthRepo.signUp('test@example.com', 'password123'),
      ).thenAnswer((_) async {});
      when(
        () => mockAuthRepo.sendEmailVerification(),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // TextFieldに入力する
      await tester.enterText(
        find.byType(TextField).at(0),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      // 登録ボタンをタップ
      await tester.tap(find.text('登録する'));
      await tester.pumpAndSettle();

      // 正しい引数で処理が呼ばれたか検証
      verify(
        () => mockAuthRepo.signUp('test@example.com', 'password123'),
      ).called(1);
      verify(() => mockAuthRepo.sendEmailVerification()).called(1);
    });

    testWidgets('サインアップ処理中、ローディング表示になり入力がロックされること', (tester) async {
      // 処理完了までに時間をかけることでローディング中を検証
      when(
        () => mockAuthRepo.signUp(any(), any()),
      ).thenAnswer(
        (_) async => Future.delayed(const Duration(milliseconds: 100)),
      );
      // sendEmailVerification のモックも念のため設定
      when(() => mockAuthRepo.sendEmailVerification()).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      await tester.tap(find.text('登録する'));

      // ポンプして画面を再描画（処理はまだ終わっていない）
      await tester.pump();

      // インジケーターが表示されていること
      check(find.byType(CircularProgressIndicator)).findsOne();

      // 非同期処理を完了させる
      await tester.pumpAndSettle();

      // ローディングが終了していること
      check(find.byType(CircularProgressIndicator)).findsNothing();
    });

    testWidgets('サインアップ失敗時(Firebaseエラー)、専用のSnackBarが表示され画面遷移しないこと', (
      tester,
    ) async {
      // メールアドレス使用済みのエラーを投げる
      when(
        () => mockAuthRepo.signUp(any(), any()),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'used@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      await tester.tap(find.text('登録する'));

      // SnackBar の表示アニメーションを1フレーム進める
      await tester.pump();

      // ErrorHandler が翻訳した「既に登録されています」の文言が表示されることを確認
      check(find.byType(SnackBar)).findsOne();
      check(find.text('このメールアドレスは既に登録されています')).findsOne();

      // 確認メール送信が呼ばれていないこと、画面遷移していないことを確認
      verifyNever(() => mockAuthRepo.sendEmailVerification());
      check(find.textContaining('Navigated to')).findsNothing();
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
  });
}
