import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_sign_up_screen.dart';
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
  bool shouldThrow = false;
  String? calledEmail;
  String? calledPassword;
  int sendEmailCallCount = 0;

  @override
  User? build() => null;

  @override
  Future<void> signUp(String email, String password) async {
    // UIのローディング状態(`isLoading = true`)をテストで確実に捉えるため、
    // ここで意図的にわずかな非同期の遅延を発生させます。
    await Future<void>.delayed(const Duration(milliseconds: 10));

    if (shouldThrow) throw Exception('SignUp Failed');
    calledEmail = email;
    calledPassword = password;
  }

  @override
  Future<void> sendEmailVerification() async {
    sendEmailCallCount++;
  }
}

void main() {
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockL10n = MockAppLocalizations();
    when(() => mockL10n.signUpTitle).thenReturn('新規登録画面');
    when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
    when(() => mockL10n.loginPasswordLabel).thenReturn('パスワード');
    when(() => mockL10n.signUp).thenReturn('登録実行');
    when(() => mockL10n.loading).thenReturn('処理中...');
    when(() => mockL10n.errorSignUpFailed).thenReturn('登録に失敗しました');
  });

  /// テスト環境のセットアップ
  Future<void> setupWidget(
    WidgetTester tester,
    FakeFirebaseAuthRepository fakeRepo,
  ) async {
    final router = GoRouter(
      initialLocation: '/sign-up',
      routes: [
        GoRoute(
          path: '/sign-up',
          builder: (context, state) => const FirebaseSignUpScreen(),
        ),
        // 遷移先のルートを Location を使って設定
        GoRoute(
          path: const EmailVerificationRoute().location,
          builder: (context, state) =>
              const Scaffold(body: Text('Email Verification Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWith(() => fakeRepo),
        ],
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
  }

  group('FirebaseSignUpScreen', () {
    testWidgets('初期表示: 入力フォームとボタンが正しく表示されること', (tester) async {
      final fakeRepo = FakeFirebaseAuthRepository();
      await setupWidget(tester, fakeRepo);

      expect(find.text('新規登録画面'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'メールアドレス'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'パスワード'), findsOneWidget);
      expect(find.text('登録実行'), findsOneWidget);
    });

    testWidgets('正常系: 入力値が渡され、メール認証が呼ばれ、遷移すること（ローディング表示も確認）', (tester) async {
      final fakeRepo = FakeFirebaseAuthRepository();
      await setupWidget(tester, fakeRepo);

      await tester.enterText(
        find.widgetWithText(TextField, 'メールアドレス'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'パスワード'),
        'password123',
      );

      // Act: ボタンをタップ
      await tester.tap(find.text('登録実行'));

      // 1回目のpump: signUpメソッド内の delayed(10ms) で処理が止まっている状態。
      // この時、画面は isLoading = true になっているので、テキストが変わるはず。
      await tester.pump();
      expect(find.text('処理中...'), findsOneWidget);
      expect(find.text('登録実行'), findsNothing); // 元のテキストは消えていること

      // 2回目のpumpAndSettle: 非同期処理を最後まで完了させる。
      await tester.pumpAndSettle();

      // Assert
      expect(fakeRepo.calledEmail, 'test@example.com');
      expect(fakeRepo.calledPassword, 'password123');
      expect(fakeRepo.sendEmailCallCount, 1);

      // 画面遷移しているか
      expect(find.text('Email Verification Screen'), findsOneWidget);
    });

    testWidgets('異常系: 例外が発生した場合、SnackBarが表示され、ローディング状態が解除されること', (
      tester,
    ) async {
      final fakeRepo = FakeFirebaseAuthRepository()..shouldThrow = true;
      await setupWidget(tester, fakeRepo);

      // Act
      await tester.tap(find.text('登録実行'));

      // 処理中の表示確認
      await tester.pump();
      expect(find.text('処理中...'), findsOneWidget);

      // 最後まで待つ（例外発生 → finallyで isLoading = false になる）
      await tester.pumpAndSettle();

      // Assert
      // 1. SnackBar が表示されたか
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('登録に失敗しました'), findsOneWidget);

      // 2. ローディングが解除され、元のボタンテキストに戻ったか
      expect(find.text('登録実行'), findsOneWidget);
      expect(find.text('処理中...'), findsNothing);

      // 3. 画面遷移していないか
      expect(find.text('新規登録画面'), findsOneWidget);
    });
  });
}
