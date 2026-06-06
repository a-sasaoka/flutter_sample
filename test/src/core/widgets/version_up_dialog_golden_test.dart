import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockAppLocalizations extends Mock implements AppLocalizations {}

class MockLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const MockLocalizationsDelegate(this.mock);
  final MockAppLocalizations mock;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => mock;
  @override
  bool shouldReload(covariant _) => false;
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
          home: Scaffold(
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
          ),
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
