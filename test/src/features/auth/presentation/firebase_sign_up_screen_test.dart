import 'dart:async';

import 'package:flutter/material.dart';
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
    when(() => mockL10n.signUpTitle).thenReturn('新規登録');
    when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
    when(() => mockL10n.loginPasswordLabel).thenReturn('パスワード');
    when(() => mockL10n.signUp).thenReturn('登録する');
    when(() => mockL10n.loading).thenReturn('ローディング中...');
    when(() => mockL10n.errorSignUpFailed).thenReturn('登録に失敗しました');
  });

  /// テスト用のWidgetを構築するヘルパー
  Widget createTestWidget() {
    final router = GoRouter(
      initialLocation: '/signup',
      routes: [
        GoRoute(
          path: '/signup',
          builder: (context, state) => const FirebaseSignUpScreen(),
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

  group('FirebaseSignUpScreen', () {
    testWidgets('UIが正しくレンダリングされること', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('新規登録'), findsOneWidget);
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.text('登録する'), findsOneWidget);
    });

    testWidgets('登録成功時: ローディング表示になり、APIが連続で呼ばれ、画面遷移すること', (tester) async {
      const email = 'test@example.com';
      const password = 'password123';

      // 処理をわざと一時停止させるために Completer を使う
      final signUpCompleter = Completer<void>();

      when(
        () => mockAuthRepo.signUp(email, password),
      ).thenAnswer((_) => signUpCompleter.future); // ここで処理が止まるようにする
      when(() => mockAuthRepo.sendEmailVerification()).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 値を入力
      await tester.enterText(find.byType(TextField).at(0), email);
      await tester.enterText(find.byType(TextField).at(1), password);

      // 登録ボタンをタップ
      await tester.tap(find.text('登録する'));

      // 1フレームだけ進めて、画面が再描画された（setStateが呼ばれた）直後の状態を作る
      await tester.pump();

      // 非同期処理中なので、ボタンの文字が「ローディング中...」に変わっていること
      expect(find.text('ローディング中...'), findsOneWidget);

      // 止めていた signUp の処理を完了（再開）させる
      signUpCompleter.complete();

      // 画面遷移（GoRouterのアニメーション）が終わるまで待機
      await tester.pumpAndSettle();

      // signUp と sendEmailVerification が両方とも1回ずつ呼ばれたか
      verify(() => mockAuthRepo.signUp(email, password)).called(1);
      verify(() => mockAuthRepo.sendEmailVerification()).called(1);

      // EmailVerificationRoute に遷移しようとして errorBuilder に落ちたか
      expect(find.textContaining('Navigated to'), findsOneWidget);
    });

    testWidgets('登録失敗時: 例外が発生した場合は SnackBar を表示し、ローディングが解除されること', (
      tester,
    ) async {
      const email = 'error@example.com';
      const password = 'password123';

      // 例外を投げるようにモックを設定
      when(
        () => mockAuthRepo.signUp(email, password),
      ).thenThrow(Exception('SignUp Error'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), email);
      await tester.enterText(find.byType(TextField).at(1), password);

      await tester.tap(find.text('登録する'));

      // SnackBarを描画するために1フレームだけ進める
      await tester.pump();

      // 例外で止まったため、後続の確認メール送信処理は呼ばれないはず
      verify(() => mockAuthRepo.signUp(email, password)).called(1);
      verifyNever(() => mockAuthRepo.sendEmailVerification());

      // 失敗メッセージの SnackBar が表示されていること
      expect(find.text('登録に失敗しました'), findsOneWidget);

      // finallyブロックが走り、ボタンの文字が元の「登録する」に戻っていること
      expect(find.text('登録する'), findsOneWidget);
      expect(find.text('ローディング中...'), findsNothing);
    });
  });
}
