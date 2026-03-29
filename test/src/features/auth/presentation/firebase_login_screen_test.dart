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
  });

  /// テスト用のWidgetを構築するヘルパー
  Widget createTestWidget() {
    final router = GoRouter(
      // 💡 画面遷移を検知するため、初期パスを専用のもの(/login)にする
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const FirebaseLoginScreen(),
        ),
      ],
      // HomeRoute や SignUpRoute への遷移をエラー画面としてキャッチする！
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

      testWidgets('ログイン失敗時(例外発生時)、SnackBarが表示されること', (tester) async {
        // 例外を投げるようにモックを設定
        when(
          () => mockAuthRepo.signIn(any(), any()),
        ).thenThrow(Exception('Login Error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('ログインする'));
        // SnackBar の表示アニメーションを1フレーム進める（pumpAndSettleだとSnackBarが消えるまで待ってしまうため）
        await tester.pump();

        // SnackBar のテキストが表示されているか確認
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
        expect(find.text('ログインに失敗しました'), findsNothing);
      });

      testWidgets('ログイン例外発生時、SnackBarが表示されること', (tester) async {
        when(
          () => mockAuthRepo.signInWithGoogle(),
        ).thenThrow(Exception('Google Login Error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Googleでログイン'));
        await tester.pump(); // SnackBar描画のために1フレーム進める

        verify(() => mockAuthRepo.signInWithGoogle()).called(1);
        expect(find.text('ログインに失敗しました'), findsOneWidget);
      });
    });
  });
}
