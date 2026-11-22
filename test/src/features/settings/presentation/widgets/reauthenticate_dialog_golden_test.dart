import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/auth/domain/account_deletion_precheck.dart';
import 'package:flutter_sample/src/features/settings/presentation/widgets/reauthenticate_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../golden_test_helper.dart';
import '../../../../core/widgets/widgets_test_helper.dart';

void main() {
  group('ReauthenticateDialog Golden Tests', () {
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockL10n = MockAppLocalizations();
      when(() => mockL10n.reauthDialogTitle).thenReturn('本人確認（再認証）');
      when(
        () => mockL10n.reauthDialogDescription,
      ).thenReturn('安全のため、退会を完了する前にもう一度本人確認を行ってください。');
      when(() => mockL10n.reauthTargetEmailLabel(any())).thenAnswer(
        (invocation) => '対象アカウント: ${invocation.positionalArguments[0]}',
      );
      when(() => mockL10n.reauthPasswordTab).thenReturn('パスワード');
      when(() => mockL10n.reauthGoogleTab).thenReturn('Google');
      when(() => mockL10n.reauthPasswordSubmit).thenReturn('パスワードで確認して続行');
      when(() => mockL10n.reauthGoogleSubmit).thenReturn('Googleアカウントで再認証');
      when(() => mockL10n.loginEmailLabel).thenReturn('メールアドレス');
      when(() => mockL10n.loginPasswordLabel).thenReturn('パスワード');
      when(
        () => mockL10n.validationEmailRequired,
      ).thenReturn('メールアドレスを入力してください');
      when(
        () => mockL10n.validationEmailInvalid,
      ).thenReturn('正しいメールアドレスの形式で入力してください');
      when(
        () => mockL10n.validationPasswordRequired,
      ).thenReturn('パスワードを入力してください');
      when(
        () => mockL10n.validationNotOnlyWhitespace,
      ).thenReturn('空白のみの入力はできません');
      when(() => mockL10n.cancel).thenReturn('キャンセル');
      when(() => mockL10n.close).thenReturn('閉じる');
    });

    // 再認証ダイアログをテスト用に描画する共通ヘルパー
    Widget buildDialogForGolden({
      required ThemeMode themeMode,
      required Set<ReauthMethod> availableMethods,
      String? email,
      String? initialErrorMessage,
      ReauthMethod? initialSelectedMethod,
    }) {
      return buildGoldenTestApp(
        themeMode: themeMode,
        additionalDelegates: [MockLocalizationsDelegate(mockL10n)],
        home: Scaffold(
          backgroundColor: Colors.black54,
          body: Center(
            child: ReauthenticateDialogContent(
              availableMethods: availableMethods,
              email: email,
              initialErrorMessage: initialErrorMessage,
              initialSelectedMethod: initialSelectedMethod,
              onPasswordSubmit: (_, _) async {},
              onGoogleSubmit: () async {},
            ),
          ),
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'ReauthenticateDialogContent の描画 (パスワードのみ・エラー表示 / ライト・ダーク)',
      fileName: 'reauthenticate_dialog_password',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Password Only - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.light,
                availableMethods: const {ReauthMethod.password},
                email: 'user@example.com',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Password Only - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.dark,
                availableMethods: const {ReauthMethod.password},
                email: 'user@example.com',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Error Banner - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.light,
                availableMethods: const {ReauthMethod.password},
                email: 'user@example.com',
                initialErrorMessage: 'パスワードが正しくありません。もう一度お試しください。',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Error Banner - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.dark,
                availableMethods: const {ReauthMethod.password},
                email: 'user@example.com',
                initialErrorMessage: 'パスワードが正しくありません。もう一度お試しください。',
              ),
            ),
          ),
        ],
      ),
    );

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'ReauthenticateDialogContent の描画 (Googleのみ・両方連携タブ / ライト・ダーク)',
      fileName: 'reauthenticate_dialog_providers',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Google Only - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.light,
                availableMethods: const {ReauthMethod.google},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Google Only - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.dark,
                availableMethods: const {ReauthMethod.google},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Both Providers - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.light,
                availableMethods: const {
                  ReauthMethod.password,
                  ReauthMethod.google,
                },
                email: 'user@example.com',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Both Providers - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.dark,
                availableMethods: const {
                  ReauthMethod.password,
                  ReauthMethod.google,
                },
                email: 'user@example.com',
              ),
            ),
          ),
        ],
      ),
    );
  });
}
