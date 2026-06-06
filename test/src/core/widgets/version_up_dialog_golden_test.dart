import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/core/widgets/version_up_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'widgets_test_helper.dart';

/// テスト開始時に自動で VersionUpDialog.show を呼び出すためのラッパーWidget
class VersionUpDialogTestWrapper extends StatefulWidget {
  const VersionUpDialogTestWrapper({
    required this.isCancelable,
    super.key,
  });
  final bool isCancelable;

  @override
  State<VersionUpDialogTestWrapper> createState() =>
      _VersionUpDialogTestWrapperState();
}

class _VersionUpDialogTestWrapperState
    extends State<VersionUpDialogTestWrapper> {
  @override
  void initState() {
    super.initState();
    // 最初のフレーム描画後に、本物の VersionUpDialog.show を呼び出す
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await VersionUpDialog.show(
          context,
          isCancelable: widget.isCancelable,
          onUpdate: () {},
          onCancel: () {},
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.expand(),
    );
  }
}

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
        child: MaterialApp(
          // 日本語フォントを適用したテーマを設定します
          theme: AppTheme.light().copyWith(
            textTheme: AppTheme.light().textTheme.apply(
              fontFamily: 'NotoSansJP',
            ),
          ),
          darkTheme: AppTheme.dark().copyWith(
            textTheme: AppTheme.dark().textTheme.apply(
              fontFamily: 'NotoSansJP',
            ),
          ),
          themeMode: themeMode,
          localizationsDelegates: [
            MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: VersionUpDialogTestWrapper(isCancelable: isCancelable),
          debugShowCheckedModeBanner: false,
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
