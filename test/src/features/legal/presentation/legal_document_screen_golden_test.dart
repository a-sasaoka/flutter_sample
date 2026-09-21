import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/features/legal/application/legal_document_provider.dart';
import 'package:flutter_sample/src/features/legal/domain/legal_document_type.dart';
import 'package:flutter_sample/src/features/legal/presentation/legal_document_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('LegalDocumentScreen Golden Tests', () {
    const sampleMarkdown = '''
# サンプル見出し1

これはテスト用の本文テキストです。

## サンプル見出し2

- リスト項目1
- リスト項目2
- [リンクのサンプル](https://example.com)

> 引用文のサンプルです。
''';

    Widget buildScreenForGolden({
      required LegalDocumentType type,
      required ThemeMode themeMode,
    }) {
      return ProviderScope(
        overrides: [
          legalDocumentProvider(
            type,
          ).overrideWith((ref) async => sampleMarkdown),
        ],
        child: MaterialApp(
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
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: LegalDocumentScreen(type: type),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'TermsOfServiceScreen の描画 (ライト/ダークモード)',
      fileName: 'terms_of_service_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildScreenForGolden(
                type: LegalDocumentType.termsOfService,
                themeMode: ThemeMode.light,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildScreenForGolden(
                type: LegalDocumentType.termsOfService,
                themeMode: ThemeMode.dark,
              ),
            ),
          ),
        ],
      ),
    );

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'PrivacyPolicyScreen の描画 (ライト/ダークモード)',
      fileName: 'privacy_policy_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildScreenForGolden(
                type: LegalDocumentType.privacyPolicy,
                themeMode: ThemeMode.light,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildScreenForGolden(
                type: LegalDocumentType.privacyPolicy,
                themeMode: ThemeMode.dark,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
