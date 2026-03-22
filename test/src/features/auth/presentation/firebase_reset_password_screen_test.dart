import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_reset_password_screen.dart';
import 'package:flutter_test/flutter_test.dart';
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
  String? calledResetEmail;

  @override
  User? build() => null;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    calledResetEmail = email;
  }
}

void main() {
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockL10n = MockAppLocalizations();
    when(() => mockL10n.resetPassword).thenReturn('パスワードリセット');
    when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
    when(() => mockL10n.send).thenReturn('送信');
    when(() => mockL10n.resetPasswordMailSent).thenReturn('リセットメールを送信しました');
  });

  /// テスト環境のセットアップ
  Future<void> setupWidget(
    WidgetTester tester,
    FakeFirebaseAuthRepository fakeRepo,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWith(() => fakeRepo),
        ],
        child: MaterialApp(
          localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
          home: const FirebaseResetPasswordScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('FirebaseResetPasswordScreen', () {
    testWidgets('初期表示: 入力フォームとボタンが正しく表示されること', (tester) async {
      final fakeRepo = FakeFirebaseAuthRepository();
      await setupWidget(tester, fakeRepo);

      expect(find.text('パスワードリセット'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'メールアドレス'), findsOneWidget);
      expect(find.text('送信'), findsOneWidget);
    });

    testWidgets('送信処理: 入力したメールアドレスがRepositoryに渡され、完了後にSnackBarが表示されること', (
      tester,
    ) async {
      final fakeRepo = FakeFirebaseAuthRepository();
      await setupWidget(tester, fakeRepo);

      // Act: メールアドレスを入力して送信ボタンをタップ
      await tester.enterText(
        find.widgetWithText(TextField, 'メールアドレス'),
        'reset@example.com',
      );
      await tester.tap(find.text('送信'));

      // SnackBarが表示されるまでアニメーションを進める
      await tester.pump();

      // Assert:
      // 1. Repositoryの sendPasswordResetEmail が正しい引数で呼ばれたか
      expect(fakeRepo.calledResetEmail, 'reset@example.com');

      // 2. 成功のSnackBarが表示されているか
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('リセットメールを送信しました'), findsOneWidget);
    });
  });
}
