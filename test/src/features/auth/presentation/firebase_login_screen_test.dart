import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モックとデリゲート ---
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

// --- Fake Repository ---
class FakeFirebaseAuthRepository extends FirebaseAuthRepository {
  // テストで挙動を操作するためのフラグ
  bool signInShouldThrow = false;
  bool googleSignInShouldThrow = false;
  bool googleSignInReturnValue = true;

  // 呼び出し確認用
  String? calledEmail;
  String? calledPassword;
  int signInWithGoogleCallCount = 0;

  @override
  User? build() => null;

  @override
  Future<void> signIn(String email, String password) async {
    if (signInShouldThrow) throw Exception('Login Failed');
    calledEmail = email;
    calledPassword = password;
  }

  @override
  Future<bool> signInWithGoogle() async {
    signInWithGoogleCallCount++;
    if (googleSignInShouldThrow) throw Exception('Google Login Failed');
    return googleSignInReturnValue;
  }
}

void main() {
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockL10n = MockAppLocalizations();
    when(() => mockL10n.loginTitle).thenReturn('ログイン画面');
    when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
    when(() => mockL10n.loginPasswordLabel).thenReturn('パスワード');
    when(() => mockL10n.login).thenReturn('ログイン実行'); // 画面タイトルと被らないように調整
    when(() => mockL10n.signUp).thenReturn('新規登録');
    when(() => mockL10n.googleSignUp).thenReturn('Googleでログイン');
    when(() => mockL10n.errorLoginFailed).thenReturn('ログインに失敗しました');
  });

  /// テスト環境のセットアップ
  Future<GoRouter> setupWidget(
    WidgetTester tester,
    FakeFirebaseAuthRepository fakeRepo,
  ) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const FirebaseLoginScreen(),
        ),
        GoRoute(
          path: const HomeRoute().location,
          builder: (context, state) =>
              const Scaffold(body: Text('Home Screen')),
        ),
        GoRoute(
          path: const SignUpRoute().location,
          builder: (context, state) =>
              const Scaffold(body: Text('SignUp Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWith(() => fakeRepo),
        ],
        // Providerが破棄されないように延命
        child: Consumer(
          builder: (context, ref, child) {
            ref.watch(firebaseAuthRepositoryProvider);
            return MaterialApp.router(
              localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
              routerConfig: router,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('FirebaseLoginScreen', () {
    testWidgets('初期表示: 入力フォームと各ボタンが正しく表示されること', (tester) async {
      final fakeRepo = FakeFirebaseAuthRepository();
      await setupWidget(tester, fakeRepo);

      expect(find.text('ログイン画面'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'メールアドレス'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'パスワード'), findsOneWidget);
      expect(find.text('ログイン実行'), findsOneWidget);
      expect(find.text('新規登録'), findsOneWidget);
      expect(find.text('Googleでログイン'), findsOneWidget);
    });

    group('メール・パスワードログイン', () {
      testWidgets('正常系: 入力値が渡され、成功するとHomeへ遷移すること', (tester) async {
        final fakeRepo = FakeFirebaseAuthRepository();
        await setupWidget(tester, fakeRepo);

        // Act
        await tester.enterText(
          find.widgetWithText(TextField, 'メールアドレス'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'パスワード'),
          'password123',
        );
        await tester.tap(find.text('ログイン実行'));
        await tester.pumpAndSettle();

        // Assert
        expect(fakeRepo.calledEmail, 'test@example.com');
        expect(fakeRepo.calledPassword, 'password123');
        // 💡 URLではなく、画面遷移後のテキストが見えるかで判定！
        expect(find.text('Home Screen'), findsOneWidget);
      });

      testWidgets('異常系: 例外が発生した場合、SnackBarでエラーメッセージを表示すること', (tester) async {
        final fakeRepo = FakeFirebaseAuthRepository()..signInShouldThrow = true;
        await setupWidget(tester, fakeRepo);

        // Act
        await tester.tap(find.text('ログイン実行'));
        await tester.pump(); // SnackBarのアニメーションを待つ

        // Assert
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('ログインに失敗しました'), findsOneWidget);
      });
    });

    group('Googleログイン', () {
      testWidgets('正常系: trueが返った場合、Homeへ遷移すること', (tester) async {
        final fakeRepo = FakeFirebaseAuthRepository()
          ..googleSignInReturnValue = true;
        await setupWidget(tester, fakeRepo);

        // Act
        await tester.tap(find.text('Googleでログイン'));
        await tester.pumpAndSettle();

        // Assert
        expect(fakeRepo.signInWithGoogleCallCount, 1);
        expect(find.text('Home Screen'), findsOneWidget);
      });

      testWidgets('キャンセル: falseが返った場合、遷移もSnackBar表示も行わないこと', (tester) async {
        final fakeRepo = FakeFirebaseAuthRepository()
          ..googleSignInReturnValue = false;
        await setupWidget(tester, fakeRepo);

        // Act
        await tester.tap(find.text('Googleでログイン'));
        await tester.pumpAndSettle();

        // Assert
        expect(fakeRepo.signInWithGoogleCallCount, 1);
        expect(find.text('Home Screen'), findsNothing); // 遷移していない
        expect(find.text('ログイン画面'), findsOneWidget); // 元の画面のまま
        expect(find.byType(SnackBar), findsNothing);
      });

      testWidgets('異常系: 例外が発生した場合、SnackBarでエラーメッセージを表示すること', (tester) async {
        final fakeRepo = FakeFirebaseAuthRepository()
          ..googleSignInShouldThrow = true;
        await setupWidget(tester, fakeRepo);

        // Act
        await tester.tap(find.text('Googleでログイン'));
        await tester.pump();

        // Assert
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('ログインに失敗しました'), findsOneWidget);
      });
    });

    group('ナビゲーション', () {
      testWidgets('新規登録ボタンタップで SignUpRoute へ遷移すること', (tester) async {
        final fakeRepo = FakeFirebaseAuthRepository();
        await setupWidget(tester, fakeRepo);

        // Act
        await tester.tap(find.text('新規登録'));
        await tester.pumpAndSettle();

        // Assert
        // ダミー画面のテキスト「SignUp Screen」が表示されていることで遷移成功を証明！
        expect(find.text('SignUp Screen'), findsOneWidget);
      });
    });
  });
}
