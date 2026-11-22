import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/settings/presentation/widgets/account_deletion_dialogs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppLocalizations extends Mock implements AppLocalizations {}

class _MockLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _MockLocalizationsDelegate(this.mock);

  final MockAppLocalizations mock;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => mock;

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

void main() {
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockL10n = MockAppLocalizations();
    when(() => mockL10n.accountDeletionStep1Title).thenReturn('アカウント削除の確認');
    when(
      () => mockL10n.accountDeletionStep1Description,
    ).thenReturn('削除すると復元できません。');
    when(() => mockL10n.accountDeletionItemAccount).thenReturn('・アカウント情報');
    when(() => mockL10n.accountDeletionItemProfile).thenReturn('・プロフィール画像');
    when(() => mockL10n.accountDeletionItemMemos).thenReturn('・すべてのメモ');
    when(() => mockL10n.accountDeletionItemHistory).thenReturn('・QRスキャン履歴');
    when(() => mockL10n.accountDeletionStep1Continue).thenReturn('退会手続きへ進む');
    when(() => mockL10n.accountDeletionStep2Title).thenReturn('最終確認');
    when(
      () => mockL10n.accountDeletionStep2Description,
    ).thenReturn('本当によろしいですか？');
    when(
      () => mockL10n.accountDeletionStep2Confirm,
    ).thenReturn('アカウントを完全に削除する');
    when(
      () => mockL10n.accountDeletionProcessing,
    ).thenReturn('アカウントとデータを削除しています...');
    when(() => mockL10n.cancel).thenReturn('キャンセル');
  });

  Widget buildApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: [
        _MockLocalizationsDelegate(mockL10n),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );
  }

  group('AccountDeletionStep1Dialog', () {
    testWidgets('キャンセル押下で false を返すこと', (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await AccountDeletionStep1Dialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      check(find.text('アカウント削除の確認')).findsOne();
      check(find.text('・アカウント情報')).findsOne();
      check(find.text('・QRスキャン履歴')).findsOne();

      await tester.tap(find.byKey(const Key('account_deletion_step1_cancel')));
      await tester.pumpAndSettle();

      check(result).equals(false);
    });

    testWidgets('続行ボタン押下で true を返し、外側タップ時は false を返すこと', (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await AccountDeletionStep1Dialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('account_deletion_step1_continue')),
      );
      await tester.pumpAndSettle();
      check(result).equals(true);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      check(result).equals(false);
    });
  });

  group('AccountDeletionStep2Dialog', () {
    testWidgets('キャンセルで false、削除確定ボタンで true を返すこと', (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await AccountDeletionStep2Dialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      check(find.text('最終確認')).findsOne();

      await tester.tap(find.byKey(const Key('account_deletion_step2_cancel')));
      await tester.pumpAndSettle();
      check(result).equals(false);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('account_deletion_step2_confirm')));
      await tester.pumpAndSettle();
      check(result).equals(true);
    });
  });

  group('AccountDeletionProcessingDialogContent', () {
    testWidgets('ローディング表示と PopScope(canPop: false) が設定されていること', (tester) async {
      await tester.pumpWidget(
        buildApp(AccountDeletionProcessingDialogContent(key: UniqueKey())),
      );
      await tester.pump();

      check(find.byType(CircularProgressIndicator)).findsOne();
      check(find.text('アカウントとデータを削除しています...')).findsOne();
      final popScope = tester.widget<PopScope<dynamic>>(
        find.byType(PopScope<dynamic>),
      );
      check(popScope.canPop).isFalse();
    });
  });
}
