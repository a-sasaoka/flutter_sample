import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/widgets/version_up_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../../golden_test_helper.dart';
import 'widgets_test_helper.dart';

void main() {
  group('VersionUpDialog Golden Tests', () {
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockL10n = MockAppLocalizations();
      when(() => mockL10n.versionUpTitle).thenReturn('アップデートのお知らせ');
      when(
        () => mockL10n.versionUpMessageOptional,
      ).thenReturn('新しいバージョンが利用可能です。アップデートしますか？');
      when(
        () => mockL10n.versionUpMessageMandatory,
      ).thenReturn('アプリを利用するには最新バージョンへのアップデートが必要です。');
      when(() => mockL10n.versionUpCancel).thenReturn('後で');
      when(() => mockL10n.versionUpUpdate).thenReturn('更新');
    });

    // ダイアログ画面をテスト用に構築する関数
    Widget buildDialogForGolden({
      required ThemeMode themeMode,
      required bool isCancelable,
    }) {
      return ProviderScope(
        child: buildGoldenTestApp(
          themeMode: themeMode,
          additionalDelegates: [MockLocalizationsDelegate(mockL10n)],
          // 💡 showDialog(useRootNavigator: true) によるテスト環境上の描画バグを回避するため、
          // 本番と共通の VersionUpDialogContent を Scaffold の body 内に直接配置して検証します。
          home: Scaffold(
            backgroundColor: Colors.black54, // ダイアログ表示時の薄暗い背景オーバーレイを模倣
            body: Center(
              child: VersionUpDialogContent(
                isCancelable: isCancelable,
                onUpdate: () {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'VersionUpDialog の描画 (ライト/ダークモード/強制・任意)',
      fileName: 'version_up_dialog',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Optional Update - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.light,
                isCancelable: true,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Optional Update - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.dark,
                isCancelable: true,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Mandatory Update - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.light,
                isCancelable: false,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Mandatory Update - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildDialogForGolden(
                themeMode: ThemeMode.dark,
                isCancelable: false,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
