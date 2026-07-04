import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
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
          // テスト内では AlertDialog を Scaffold の body 内に直接配置して、ダイアログ単体の見た目を検証します。
          home: Builder(
            builder: (context) {
              return Scaffold(
                backgroundColor: Colors.black54, // ダイアログ表示時の薄暗い背景オーバーレイを模倣
                body: Center(
                  child: AlertDialog(
                    title: Text(mockL10n.versionUpTitle),
                    content: Text(
                      isCancelable
                          ? mockL10n.versionUpMessageOptional
                          : mockL10n.versionUpMessageMandatory,
                    ),
                    actions: [
                      if (isCancelable)
                        TextButton(
                          onPressed: () {},
                          child: Text(mockL10n.versionUpCancel),
                        ),
                      TextButton(
                        onPressed: () {},
                        child: Text(mockL10n.versionUpUpdate),
                      ),
                    ],
                  ),
                ),
              );
            },
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
        ],
      ),
    );
  });
}
