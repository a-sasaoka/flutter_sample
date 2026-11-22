import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/exceptions/reauth_exception.dart';
import 'package:flutter_sample/src/features/auth/domain/account_deletion_precheck.dart';
import 'package:flutter_sample/src/features/settings/presentation/widgets/reauthenticate_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockL10n = MockAppLocalizations();
    when(() => mockL10n.reauthDialogTitle).thenReturn('本人確認（再認証）');
    when(
      () => mockL10n.reauthDialogDescription,
    ).thenReturn('もう一度本人確認を行ってください。');
    when(() => mockL10n.reauthTargetEmailLabel(any())).thenAnswer(
      (invocation) => '対象アカウント: ${invocation.positionalArguments[0]}',
    );
    when(() => mockL10n.reauthPasswordTab).thenReturn('パスワード');
    when(() => mockL10n.reauthGoogleTab).thenReturn('Google');
    when(() => mockL10n.reauthPasswordSubmit).thenReturn('パスワードで確認して続行');
    when(() => mockL10n.reauthGoogleSubmit).thenReturn('Googleアカウントで再認証');
    when(
      () => mockL10n.reauthUnavailableProvider,
    ).thenReturn('再認証方法が見つかりませんでした。');
    when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
    when(() => mockL10n.loginPasswordLabel).thenReturn('パスワード欄');
    when(() => mockL10n.validationEmailRequired).thenReturn('メール必須');
    when(() => mockL10n.validationEmailInvalid).thenReturn('メール形式不正');
    when(() => mockL10n.validationPasswordRequired).thenReturn('パスワード必須');
    when(() => mockL10n.validationNotOnlyWhitespace).thenReturn('空白のみ禁止');
    when(() => mockL10n.errorWrongPassword).thenReturn('パスワードが正しくありません。');
    when(() => mockL10n.errorUserMismatch).thenReturn('別アカウントが選択されました。');
    when(
      () => mockL10n.errorReauthInvalidCredential,
    ).thenReturn('資格情報の確認に失敗しました。');
    when(() => mockL10n.cancel).thenReturn('キャンセル');
    when(() => mockL10n.close).thenReturn('閉じる');
  });

  void setMobileView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    // 論理サイズをスマホ相当の 360×640 に合わせる
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget buildLauncherApp({
    required Set<ReauthMethod> availableMethods,
    required Future<void> Function(String password, String? email)
    onPasswordSubmit,
    required Future<void> Function() onGoogleSubmit,
    required ValueChanged<bool> onResult,
    String? email,
  }) {
    return MaterialApp(
      localizationsDelegates: [
        _MockLocalizationsDelegate(mockL10n),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await ReauthenticateDialog.show(
                context,
                availableMethods: availableMethods,
                email: email,
                onPasswordSubmit: onPasswordSubmit,
                onGoogleSubmit: onGoogleSubmit,
              );
              onResult(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('ReauthenticateDialog', () {
    testWidgets('利用可能な認証方法が空の場合、案内を表示して閉じるで false を返すこと', (tester) async {
      setMobileView(tester);
      bool? result;
      await tester.pumpWidget(
        buildLauncherApp(
          availableMethods: const {},
          onPasswordSubmit: (_, _) async {},
          onGoogleSubmit: () async {},
          onResult: (value) => result = value,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      check(find.text('再認証方法が見つかりませんでした。')).findsOne();

      await tester.tap(find.byKey(const Key('reauth_close_button')));
      await tester.pumpAndSettle();

      check(result).equals(false);
    });

    testWidgets('パスワードのみ（メールあり）: バリデーション・表示切替・エラー再試行・成功時 true を検証できること', (
      tester,
    ) async {
      setMobileView(tester);
      bool? result;
      var shouldFail = true;
      String? submittedPassword;
      String? submittedEmail;

      await tester.pumpWidget(
        buildLauncherApp(
          availableMethods: const {ReauthMethod.password},
          email: 'user@example.com',
          onPasswordSubmit: (password, email) async {
            submittedPassword = password;
            submittedEmail = email;
            if (shouldFail) {
              throw const ReauthWrongPasswordException();
            }
          },
          onGoogleSubmit: () async {},
          onResult: (value) => result = value,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      check(find.text('対象アカウント: user@example.com')).findsOne();
      check(find.byKey(const Key('reauth_method_selector'))).findsNothing();
      check(find.byKey(const Key('reauth_email_field'))).findsNothing();

      // 空送信でバリデーションエラー
      await tester.tap(find.byKey(const Key('reauth_password_submit_button')));
      await tester.pump();
      check(find.text('パスワード必須')).findsOne();
      check(submittedPassword).isNull();

      // 表示切替トグル
      final passwordFieldFinder = find.descendant(
        of: find.byKey(const Key('reauth_password_field')),
        matching: find.byType(EditableText),
      );
      check(
        tester.widget<EditableText>(passwordFieldFinder).obscureText,
      ).isTrue();
      await tester.tap(
        find.byKey(const Key('reauth_password_visibility_toggle')),
      );
      await tester.pump();
      check(
        tester.widget<EditableText>(passwordFieldFinder).obscureText,
      ).isFalse();

      // パスワード誤りでダイアログ内にエラー表示され、閉じないこと
      await tester.enterText(
        find.byKey(const Key('reauth_password_field')),
        'wrong-pass',
      );
      await tester.tap(find.byKey(const Key('reauth_password_submit_button')));
      await tester.pumpAndSettle();

      check(find.byKey(const Key('reauth_error_banner'))).findsOne();
      check(find.text('パスワードが正しくありません。')).findsOne();
      check(result).isNull();

      // 正しいパスワードで再試行して true を返すこと
      shouldFail = false;
      await tester.enterText(
        find.byKey(const Key('reauth_password_field')),
        'correct-pass',
      );
      await tester.tap(find.byKey(const Key('reauth_password_submit_button')));
      await tester.pumpAndSettle();

      check(submittedPassword).equals('correct-pass');
      check(submittedEmail).equals('user@example.com');
      check(result).equals(true);
    });

    testWidgets('パスワードのみ（メール未設定時）: メール入力欄が表示され、検証後に送信できること', (tester) async {
      setMobileView(tester);
      bool? result;
      String? submittedEmail;
      String? submittedPassword;

      await tester.pumpWidget(
        buildLauncherApp(
          availableMethods: const {ReauthMethod.password},
          onPasswordSubmit: (password, email) async {
            submittedPassword = password;
            submittedEmail = email;
          },
          onGoogleSubmit: () async {},
          onResult: (value) => result = value,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      check(find.byKey(const Key('reauth_email_field'))).findsOne();

      await tester.enterText(
        find.byKey(const Key('reauth_email_field')),
        'custom@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('reauth_password_field')),
        'pass1234',
      );
      await tester.tap(find.byKey(const Key('reauth_password_submit_button')));
      await tester.pumpAndSettle();

      check(submittedEmail).equals('custom@example.com');
      check(submittedPassword).equals('pass1234');
      check(result).equals(true);
    });

    testWidgets(
      'Googleのみ: 送信中ロック・userMismatch時エラー表示・成功時 true・キャンセルで false を返すこと',
      (tester) async {
        setMobileView(tester);
        bool? result;
        Completer<void>? completer;
        var throwMismatch = true;

        await tester.pumpWidget(
          buildLauncherApp(
            availableMethods: const {ReauthMethod.google},
            onPasswordSubmit: (_, _) async {},
            onGoogleSubmit: () async {
              if (completer != null) {
                await completer.future;
                return;
              }
              if (throwMismatch) {
                throw const ReauthUserMismatchException();
              }
            },
            onResult: (value) => result = value,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        check(find.byKey(const Key('reauth_method_selector'))).findsNothing();
        check(find.byKey(const Key('reauth_google_submit_button'))).findsOne();

        // userMismatch でエラー表示
        await tester.tap(find.byKey(const Key('reauth_google_submit_button')));
        await tester.pumpAndSettle();
        check(find.text('別アカウントが選択されました。')).findsOne();
        check(result).isNull();

        // 送信中ローディングと PopScope(canPop: false)
        throwMismatch = false;
        completer = Completer<void>();
        await tester.tap(find.byKey(const Key('reauth_google_submit_button')));
        await tester.pump();

        final popScope = tester.widget<PopScope<dynamic>>(
          find.byType(PopScope<dynamic>),
        );
        check(popScope.canPop).isFalse();

        completer.complete();
        await tester.pumpAndSettle();
        check(result).equals(true);

        // 再度開いてキャンセルで false
        result = null;
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('reauth_cancel_button')));
        await tester.pumpAndSettle();
        check(result).equals(false);
      },
    );

    testWidgets('両方連携時: SegmentedButtonで方式切替時にエラーがクリアされ、各方式で送信できること', (
      tester,
    ) async {
      setMobileView(tester);
      bool? result;
      var googleCalled = 0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [
            _MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: ReauthenticateDialogContent(
              availableMethods: const {
                ReauthMethod.password,
                ReauthMethod.google,
              },
              email: 'both@example.com',
              initialErrorMessage: '初期エラー',
              initialSelectedMethod: ReauthMethod.google,
              onPasswordSubmit: (_, _) async {},
              onGoogleSubmit: () async {
                googleCalled++;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      check(find.byKey(const Key('reauth_method_selector'))).findsOne();
      check(find.byKey(const Key('reauth_error_banner'))).findsOne();
      check(find.byKey(const Key('reauth_google_submit_button'))).findsOne();

      // パスワードタブへ切り替えるとエラーバナーが消えること
      await tester.tap(find.text('パスワード'));
      await tester.pumpAndSettle();
      check(find.byKey(const Key('reauth_error_banner'))).findsNothing();
      check(find.byKey(const Key('reauth_password_field'))).findsOne();

      // 再びGoogleタブに戻して実行
      await tester.pumpWidget(
        buildLauncherApp(
          availableMethods: const {ReauthMethod.password, ReauthMethod.google},
          email: 'both@example.com',
          onPasswordSubmit: (_, _) async {},
          onGoogleSubmit: () async {
            googleCalled++;
          },
          onResult: (value) => result = value,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Google'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reauth_google_submit_button')));
      await tester.pumpAndSettle();

      check(googleCalled).equals(1);
      check(result).equals(true);
    });
  });
}
