import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/settings/presentation/widgets/account_deletion_dialogs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../golden_test_helper.dart';
import '../../../../core/widgets/widgets_test_helper.dart';

void main() {
  group('AccountDeletionDialogs Golden Tests', () {
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockL10n = MockAppLocalizations();
      when(() => mockL10n.accountDeletionStep1Title).thenReturn('アカウント削除の確認');
      when(
        () => mockL10n.accountDeletionStep1Description,
      ).thenReturn('アカウントを削除すると、以下のデータが完全に消去され、元に戻すことはできません。');
      when(
        () => mockL10n.accountDeletionItemAccount,
      ).thenReturn('・アカウントおよびログイン情報');
      when(
        () => mockL10n.accountDeletionItemProfile,
      ).thenReturn('・プロフィール情報およびアバター画像');
      when(
        () => mockL10n.accountDeletionItemMemos,
      ).thenReturn('・クラウドおよび端末内のすべてのメモ');
      when(
        () => mockL10n.accountDeletionItemHistory,
      ).thenReturn('・QRスキャン履歴・キャッシュ・アプリロック設定');
      when(() => mockL10n.accountDeletionStep1Continue).thenReturn('退会手続きへ進む');
      when(() => mockL10n.accountDeletionStep2Title).thenReturn('最終確認');
      when(
        () => mockL10n.accountDeletionStep2Description,
      ).thenReturn('本当によろしいですか？\nこの操作は取り消せません。アカウントと関連する全データが完全に削除されます。');
      when(
        () => mockL10n.accountDeletionStep2Confirm,
      ).thenReturn('アカウントを完全に削除する');
      when(
        () => mockL10n.accountDeletionProcessing,
      ).thenReturn('アカウントとデータを削除しています...');
      when(() => mockL10n.cancel).thenReturn('キャンセル');
    });

    // ダイアログ単体をテスト用に描画する共通ヘルパー
    Widget buildDialogForGolden({
      required ThemeMode themeMode,
      required Widget dialog,
    }) {
      return buildGoldenTestApp(
        themeMode: themeMode,
        additionalDelegates: [MockLocalizationsDelegate(mockL10n)],
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
