import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モッククラスの定義 ---

class MockFirebaseAuthRepository extends Mock
    implements FirebaseAuthRepository {}

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
  late MockFirebaseAuthRepository mockAuthRepo;
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockAuthRepo = MockFirebaseAuthRepository();
    mockL10n = MockAppLocalizations();

    // 多言語化のスタブ
    when(() => mockL10n.loginTitle).thenReturn('ログイン');
    when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
    when(() => mockL10n.loginPasswordLabel).thenReturn('パスワード');
    when(() => mockL10n.login).thenReturn('ログインする');
    when(() => mockL10n.signUp).thenReturn('新規登録へ');
    when(() => mockL10n.googleSignUp).thenReturn('Googleでログイン');
    when(() => mockL10n.errorLoginFailed).thenReturn('ログインに失敗しました');
    when(() => mockL10n.errorUnknown).thenReturn('予期しないエラーが発生しました');
    when(() => mockL10n.close).thenReturn('閉じる');
  });

  /// テスト用のWidgetを構築するヘルパー
  Widget createTestWidget() {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const FirebaseLoginScreen(),
        ),
      ],
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
        localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
      ),
    );
  }

  group('FirebaseLoginScreen', () {
    testWidgets('UIが正しくレンダリングされること', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ログイン'), findsOneWidget);
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.text('ログインする'), findsOneWidget);
      expect(find.text('新規登録へ'), findsOneWidget);
      expect(find.text('Googleでログイン'), findsOneWidget);
    });

    group('メール・パスワードログイン', () {
      testWidgets('入力値が Repository に渡され、成功時に HomeRoute に遷移すること', (
        tester,
      ) async {
        when(
          () => mockAuthRepo.signIn('test@example.com', 'password123'),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // TextFieldに入力する
        await tester.enterText(
          find.byType(TextField).at(0),
          'test@example.com',
        );
        await tester.enterText(find.byType(TextField).at(1), 'password123');

        // ログインボタンをタップ
        await tester.tap(find.text('ログインする'));
        await tester.pumpAndSettle();

        // 正しい引数で signIn が呼ばれたか検証
        verify(
          () => mockAuthRepo.signIn('test@example.com', 'password123'),
        ).called(1);

        // 画面遷移したことを確認
        expect(find.textContaining('Navigated to'), findsOneWidget);
      });

      testWidgets('ログイン処理中、ローディング表示になり入力がロックされること', (tester) async {
        // 処理完了までに時間をかけることでローディング中を検証
        when(
          () => mockAuthRepo.signIn(any(), any()),
        ).thenAnswer(
          (_) async => Future.delayed(const Duration(milliseconds: 100)),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('ログインする'));

        // ポンプして画面を再描画（処理はまだ終わっていない）
        await tester.pump();

        // インジケーターが表示されていること
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // 非同期処理を完了させる
        await tester.pumpAndSettle();

        // ローディングが終了していること
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('ログイン失敗時(FirebaseAuthException発生時)、専用のSnackBarが表示されること', (
        tester,
      ) async {
        // FirebaseAuthException を投げることで、ErrorHandler が適切な翻訳文言を返すことを確認
        when(
          () => mockAuthRepo.signIn(any(), any()),
        ).thenThrow(FirebaseAuthException(code: 'wrong-password'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('ログインする'));

        // SnackBar の表示アニメーションを1フレーム進める
        await tester.pump();

        // SnackBar とテキストが表示されているか確認
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('ログインに失敗しました'), findsOneWidget);
      });
    });

    group('新規登録', () {
      testWidgets('新規登録ボタンタップ時、SignUpRouteに遷移すること', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('新規登録へ'));
        await tester.pumpAndSettle();

        // 画面遷移したことを確認
        expect(find.textContaining('Navigated to'), findsOneWidget);
      });
    });

    group('Googleログイン', () {
      testWidgets('ログイン成功時(trueを返す場合)、HomeRouteに遷移すること', (tester) async {
        when(
          () => mockAuthRepo.signInWithGoogle(),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Googleでログイン'));
        await tester.pumpAndSettle();

        verify(() => mockAuthRepo.signInWithGoogle()).called(1);
        expect(find.textContaining('Navigated to'), findsOneWidget);
      });

      testWidgets('ログインキャンセル時(falseを返す場合)、何も起きないこと', (tester) async {
        when(
          () => mockAuthRepo.signInWithGoogle(),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Googleでログイン'));
        await tester.pumpAndSettle();

        verify(() => mockAuthRepo.signInWithGoogle()).called(1);

        // 画面遷移せず、エラーSnackBarも出ないことを確認
        expect(find.textContaining('Navigated to'), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
      });

      testWidgets('ログイン処理中、ローディングインジケーターが表示されること', (tester) async {
        when(
          () => mockAuthRepo.signInWithGoogle(),
        ).thenAnswer(
          (_) async =>
              Future.delayed(const Duration(milliseconds: 100), () => true),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Googleでログイン'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();
      });

      testWidgets('ログイン例外発生時(一般的なException)、汎用のSnackBarが表示されること', (
        tester,
      ) async {
        when(
          () => mockAuthRepo.signInWithGoogle(),
        ).thenThrow(Exception('Google Login Error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Googleでログイン'));
        await tester.pump(); // SnackBar描画のために1フレーム進める

        verify(() => mockAuthRepo.signInWithGoogle()).called(1);

        // 一般的な Exception なので ErrorHandler が「予期しないエラー」にフォールバックすることを確認
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('予期しないエラーが発生しました'), findsOneWidget);
      });
    });
  });
}
