import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/widgets/version_up_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'widgets_test_helper.dart';

void main() {
  group('VersionUpDialog', () {
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockL10n = MockAppLocalizations();

      when(() => mockL10n.versionUpTitle).thenReturn('Version Update');
      when(
        () => mockL10n.versionUpMessageOptional,
      ).thenReturn('A new version is available.');
      when(
        () => mockL10n.versionUpMessageMandatory,
      ).thenReturn('A new version is required.');
      when(() => mockL10n.versionUpCancel).thenReturn('Later');
      when(() => mockL10n.versionUpUpdate).thenReturn('Update');
    });

    // テスト用のウィジェットを構築するヘルパー関数
    Widget createTestWidget(
      void Function(BuildContext) showDialogCallback,
    ) {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showDialogCallback(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ],
      );

      return MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: [
          MockLocalizationsDelegate(mockL10n),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ja'), Locale('en')],
      );
    }

    testWidgets('キャンセル可能なダイアログが表示され、各ボタンが動作すること', (tester) async {
      var onUpdateCalled = false;
      var onCancelCalled = false;

      await tester.pumpWidget(
        createTestWidget((context) async {
          await VersionUpDialog.show(
            context,
            isCancelable: true,
            onUpdate: () => onUpdateCalled = true,
            onCancel: () => onCancelCalled = true,
          );
        }),
      );
      await tester.pumpAndSettle();

      // ダイアログ表示
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      check(find.byType(AlertDialog)).findsOne();
      check(find.text(mockL10n.versionUpMessageOptional)).findsOne();
      check(
        find.widgetWithText(TextButton, mockL10n.versionUpCancel),
      ).findsOne();
      check(
        find.widgetWithText(TextButton, mockL10n.versionUpUpdate),
      ).findsOne();

      // アップデートボタン
      await tester.tap(
        find.widgetWithText(TextButton, mockL10n.versionUpUpdate),
      );
      await tester.pumpAndSettle();
      check(onUpdateCalled).equals(true);
      check(find.byType(AlertDialog)).findsNothing();

      // 再表示してキャンセルボタン
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, mockL10n.versionUpCancel),
      );
      await tester.pumpAndSettle();
      check(onCancelCalled).equals(true);
      check(find.byType(AlertDialog)).findsNothing();
    });

    testWidgets('強制アップデートダイアログが表示され、キャンセル不可であること', (tester) async {
      var onUpdateCalled = false;

      await tester.pumpWidget(
        createTestWidget((context) async {
          await VersionUpDialog.show(
            context,
            isCancelable: false,
            onUpdate: () => onUpdateCalled = true,
            onCancel: () {},
          );
        }),
      );
      await tester.pumpAndSettle();

      // ダイアログ表示
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      check(find.byType(AlertDialog)).findsOne();
      check(find.text(mockL10n.versionUpMessageMandatory)).findsOne();
      check(
        find.widgetWithText(TextButton, mockL10n.versionUpCancel),
      ).findsNothing();

      // ダイアログ外タップで閉じないこと
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      check(find.byType(AlertDialog)).findsOne();

      // アップデート
      await tester.tap(
        find.widgetWithText(TextButton, mockL10n.versionUpUpdate),
      );
      await tester.pumpAndSettle();
      check(onUpdateCalled).equals(true);
      check(find.byType(AlertDialog)).findsNothing();
    });

    testWidgets('キャンセル可能な場合にダイアログ外をタップするとキャンセル扱いになること', (tester) async {
      var onCancelCalled = false;

      await tester.pumpWidget(
        createTestWidget((context) async {
          await VersionUpDialog.show(
            context,
            isCancelable: true,
            onUpdate: () {},
            onCancel: () => onCancelCalled = true,
          );
        }),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // ダイアログ外タップ
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      check(onCancelCalled).equals(true);
      check(find.byType(AlertDialog)).findsNothing();
    });
  });
}
