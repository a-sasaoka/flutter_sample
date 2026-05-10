import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/widgets/version_up_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('VersionUpDialog', () {
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
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
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

      // ダイアログ表示
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('A new version is available.'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Later'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Update'), findsOneWidget);

      // アップデートボタン
      await tester.tap(find.widgetWithText(TextButton, 'Update'));
      await tester.pumpAndSettle();
      expect(onUpdateCalled, isTrue);
      expect(find.byType(AlertDialog), findsNothing);

      // 再表示してキャンセルボタン
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Later'));
      await tester.pumpAndSettle();
      expect(onCancelCalled, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
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

      // ダイアログ表示
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('A new version is required.'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Later'), findsNothing);

      // ダイアログ外タップで閉じないこと
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // アップデート
      await tester.tap(find.widgetWithText(TextButton, 'Update'));
      await tester.pumpAndSettle();
      expect(onUpdateCalled, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
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

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // ダイアログ外タップ
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      expect(onCancelCalled, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
