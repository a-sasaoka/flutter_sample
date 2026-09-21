import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/legal/application/legal_document_provider.dart';
import 'package:flutter_sample/src/features/legal/domain/legal_document_type.dart';
import 'package:flutter_sample/src/features/legal/presentation/legal_document_screen.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/url_launcher_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class MockUrlLauncherService extends Mock implements UrlLauncherService {}

class MockAssetBundle extends Mock implements AssetBundle {}

void main() {
  group('LegalDocumentScreen', () {
    late MockUrlLauncherService mockUrlLauncherService;

    setUp(() {
      mockUrlLauncherService = MockUrlLauncherService();
    });

    Widget createTestWidget({
      required LegalDocumentType type,
      List<Override> overrides = const [],
    }) {
      return ProviderScope(
        overrides: [
          urlLauncherServiceProvider.overrideWithValue(mockUrlLauncherService),
          ...overrides,
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: LegalDocumentScreen(type: type),
        ),
      );
    }

    testWidgets('利用規約の画面が正常に表示されること', (tester) async {
      const markdownContent = '# 利用規約本文\n\n利用規約の内容です。';

      await tester.pumpWidget(
        createTestWidget(
          type: LegalDocumentType.termsOfService,
          overrides: [
            legalDocumentProvider(
              LegalDocumentType.termsOfService,
            ).overrideWith((ref) async => markdownContent),
          ],
        ),
      );
      await tester.pumpAndSettle();

      check(find.text('利用規約')).findsOne();
      check(find.byType(Markdown)).findsOne();
      check(find.textContaining('利用規約本文')).findsOne();
    });

    testWidgets('プライバシーポリシーの画面が正常に表示されること', (tester) async {
      const markdownContent = '# プライバシーポリシー本文\n\nプライバシーポリシーの内容です。';

      await tester.pumpWidget(
        createTestWidget(
          type: LegalDocumentType.privacyPolicy,
          overrides: [
            legalDocumentProvider(
              LegalDocumentType.privacyPolicy,
            ).overrideWith((ref) async => markdownContent),
          ],
        ),
      );
      await tester.pumpAndSettle();

      check(find.text('プライバシーポリシー')).findsOne();
      check(find.byType(Markdown)).findsOne();
      check(find.textContaining('プライバシーポリシー本文')).findsOne();
    });

    testWidgets('ローディング中は CircularProgressIndicator が表示されること', (tester) async {
      final completer = Completer<String>();

      await tester.pumpWidget(
        createTestWidget(
          type: LegalDocumentType.termsOfService,
          overrides: [
            legalDocumentProvider(
              LegalDocumentType.termsOfService,
            ).overrideWith((ref) => completer.future),
          ],
        ),
      );
      await tester.pump();

      check(find.byType(CircularProgressIndicator)).findsOne();
      check(find.byType(Markdown)).findsNothing();

      // Completerを解決して終了処理
      completer.complete('完了');
      await tester.pumpAndSettle();
    });

    testWidgets('エラー時はエラーメッセージと再試行ボタンが表示され、再試行ボタンを押すとリフレッシュされること', (
      tester,
    ) async {
      final mockAssetBundle = MockAssetBundle();
      // 初期読み込み時はエラーを返す
      when(
        () => mockAssetBundle.loadString(any()),
      ).thenAnswer((_) => Future.error(Exception('Failed to load markdown')));

      await tester.pumpWidget(
        createTestWidget(
          type: LegalDocumentType.termsOfService,
          overrides: [assetBundleProvider.overrideWithValue(mockAssetBundle)],
        ),
      );
      await tester.pumpAndSettle();

      check(find.text('ドキュメントの読み込みに失敗しました')).findsOne();
      check(find.byIcon(Icons.error_outline)).findsOne();
      final retryButton = find.widgetWithText(FilledButton, '再試行');
      check(retryButton).findsOne();

      // 再試行時は成功するように設定を更新
      when(
        () => mockAssetBundle.loadString(any()),
      ).thenAnswer((_) => Future.value('# 再読み込み成功'));

      // 再試行ボタンをタップ
      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      check(find.textContaining('再読み込み成功')).findsOne();
      check(find.text('ドキュメントの読み込みに失敗しました')).findsNothing();
    });

    testWidgets('Markdown内のリンクタップ時に UrlLauncherService.openUrl が呼ばれ、成功すること', (
      tester,
    ) async {
      const linkUrl = 'https://example.com/terms';
      const markdownContent = '[利用規約リンク]($linkUrl)';

      when(
        () => mockUrlLauncherService.openUrl(linkUrl),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        createTestWidget(
          type: LegalDocumentType.termsOfService,
          overrides: [
            legalDocumentProvider(
              LegalDocumentType.termsOfService,
            ).overrideWith((ref) async => markdownContent),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Markdown ウィジェットを取得して onTapLink を検証
      final markdownFinder = find.byType(Markdown);
      check(markdownFinder).findsOne();
      final markdownWidget = tester.widget<Markdown>(markdownFinder);

      // onTapLink コールバックを直接実行
      markdownWidget.onTapLink!('利用規約リンク', linkUrl, '利用規約リンク');
      await tester.pumpAndSettle();

      verify(() => mockUrlLauncherService.openUrl(linkUrl)).called(1);
      check(find.byType(SnackBar)).findsNothing();
    });

    testWidgets('Markdown内のリンクタップ時に href が null の場合は openUrl が呼ばれないこと', (
      tester,
    ) async {
      const markdownContent = 'プレーンテキスト';

      await tester.pumpWidget(
        createTestWidget(
          type: LegalDocumentType.termsOfService,
          overrides: [
            legalDocumentProvider(
              LegalDocumentType.termsOfService,
            ).overrideWith((ref) async => markdownContent),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final markdownWidget = tester.widget<Markdown>(find.byType(Markdown));
      markdownWidget.onTapLink!('リンク', null, 'タイトル');
      await tester.pumpAndSettle();

      verifyNever(() => mockUrlLauncherService.openUrl(any()));
      check(find.byType(SnackBar)).findsNothing();
    });

    testWidgets('Markdown内のリンク起動に失敗した場合にエラーSnackBarが表示されること', (tester) async {
      const linkUrl = 'https://example.com/invalid';
      const markdownContent = '[無効なリンク]($linkUrl)';

      when(
        () => mockUrlLauncherService.openUrl(linkUrl),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        createTestWidget(
          type: LegalDocumentType.termsOfService,
          overrides: [
            legalDocumentProvider(
              LegalDocumentType.termsOfService,
            ).overrideWith((ref) async => markdownContent),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final markdownWidget = tester.widget<Markdown>(find.byType(Markdown));
      markdownWidget.onTapLink!('無効なリンク', linkUrl, '無効なリンク');
      await tester.pumpAndSettle();

      verify(() => mockUrlLauncherService.openUrl(linkUrl)).called(1);
      check(find.text('リンクを開けませんでした')).findsOne();
    });
  });
}
