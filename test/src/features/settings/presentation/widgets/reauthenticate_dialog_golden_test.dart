import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/auth/domain/account_deletion_precheck.dart';
import 'package:flutter_sample/src/features/settings/presentation/widgets/reauthenticate_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../golden_test_helper.dart';

void main() {
  group('ReauthenticateDialog Golden Tests', () {
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
