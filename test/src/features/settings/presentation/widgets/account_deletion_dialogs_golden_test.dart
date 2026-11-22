import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/settings/presentation/widgets/account_deletion_dialogs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../golden_test_helper.dart';

void main() {
  group('AccountDeletionDialogs Golden Tests', () {
    // ダイアログ単体をテスト用に描画する共通ヘルパー
    Widget buildDialogForGolden({
      required ThemeMode themeMode,
      required Widget dialog,
    }) {
      return buildGoldenTestApp(
        themeMode: themeMode,
        // showDialog 経由のテスト環境描画崩れを避けるため、
        // 薄暗い背景の上に本番と共通の *DialogContent を直接配置して検証します。
        home: Scaffold(
          backgroundColor: Colors.black54,
          body: Center(child: dialog),
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'AccountDeletionStep1DialogContent の描画 (ライト/ダークモード)',
      fileName: 'account_deletion_step1_dialog',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.light,
                dialog: const AccountDeletionStep1DialogContent(),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.dark,
                dialog: const AccountDeletionStep1DialogContent(),
              ),
            ),
          ),
        ],
      ),
    );

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'AccountDeletionStep2DialogContent の描画 (ライト/ダークモード)',
      fileName: 'account_deletion_step2_dialog',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.light,
                dialog: const AccountDeletionStep2DialogContent(),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.dark,
                dialog: const AccountDeletionStep2DialogContent(),
              ),
            ),
          ),
        ],
      ),
    );

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'AccountDeletionProcessingDialogContent の描画 (ライト/ダークモード)',
      fileName: 'account_deletion_processing_dialog',
      // CircularProgressIndicator の無限アニメーションによるタイムアウトを防ぐため 1回のみ pump します
      pumpBeforeTest: (tester) => tester.pump(),
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.light,
                dialog: const AccountDeletionProcessingDialogContent(),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.dark,
                dialog: const AccountDeletionProcessingDialogContent(),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
