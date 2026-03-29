import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_reset_password_screen.dart';
import 'package:flutter_test/flutter_test.dart';
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
    when(() => mockL10n.resetPassword).thenReturn('パスワードリセット');
    when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
    when(() => mockL10n.send).thenReturn('送信する');
    when(() => mockL10n.resetPasswordMailSent).thenReturn('リセットメールを送信しました');
  });

  /// テスト用のWidgetを構築するヘルパー
  Widget createTestWidget() {
    // 画面遷移（GoRouter）がないので、シンプルな MaterialApp で十分です
    return ProviderScope(
      overrides: [
        firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
      child: MaterialApp(
        home: const FirebaseResetPasswordScreen(),
        localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
      ),
    );
  }

  group('FirebaseResetPasswordScreen', () {
    testWidgets('UIが正しくレンダリングされること', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('パスワードリセット'), findsOneWidget);
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('送信する'), findsOneWidget);
    });

    testWidgets('メールアドレスを入力して送信ボタンを押すと、リセット処理が呼ばれSnackBarが表示されること', (
      tester,
    ) async {
      const testEmail = 'test@example.com';

      // モックの設定：テスト用のメールアドレスが渡されたら成功（空のFuture）を返す
      when(
        () => mockAuthRepo.sendPasswordResetEmail(testEmail),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. TextField にメールアドレスを入力
      await tester.enterText(find.byType(TextField), testEmail);

      // 2. 送信ボタンをタップ
      await tester.tap(find.text('送信する'));

      // 3. SnackBar の表示アニメーションを1フレーム進める
      await tester.pump();

      // Repository のメソッドが正しい引数で1回呼ばれたか
      verify(() => mockAuthRepo.sendPasswordResetEmail(testEmail)).called(1);

      // 成功メッセージの SnackBar が表示されているか
      expect(find.text('リセットメールを送信しました'), findsOneWidget);
    });
  });
}
