import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';
import 'package:flutter_sample/src/core/widgets/version_up_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

// `CancelController`をテスト用に拡張し、メソッド呼び出しを追跡できるようにします。
class TestCancelController extends CancelController {
  bool clickCancelCalled = false;

  @override
  void clickCancel() {
    super.clickCancel();
    clickCancelCalled = true;
  }
}

void main() {
  group('VersionUpDialog', () {
    // テスト用のウィジェットを構築するヘルパー関数
    Widget createTestWidget(
      void Function(BuildContext, WidgetRef) showDialogCallback,
    ) {
      return ProviderScope(
        overrides: [
          // `cancelControllerProvider`をテスト用のコントローラで上書きします。
          cancelControllerProvider.overrideWith(TestCancelController.new),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            return MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => showDialogCallback(context, ref),
                      child: const Text('Show Dialog'),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    testWidgets('UpdateRequestType.notの場合、ダイアログは表示されない', (tester) async {
      await tester.pumpWidget(
        createTestWidget((context, ref) async {
          await VersionUpDialog.show(context, UpdateRequestType.not, ref);
        }),
      );

      // ダイアログ表示ボタンをタップ
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // ダイアログが表示されていないことを確認
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('UpdateRequestType.cancelableの場合、キャンセル可能なダイアログが表示される', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget((context, ref) async {
          await VersionUpDialog.show(
            context,
            UpdateRequestType.cancelable,
            ref,
          );
        }),
      );

      // ダイアログ表示ボタンをタップ
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // ダイアログと各要素が表示されていることを確認
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('A new version is available.\nPlease update.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Update'), findsOneWidget);

      // キャンセルボタンをタップ
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // ダイアログが閉じていることを確認
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
      'UpdateRequestType.cancelableでダイアログ外をタップするとダイアログが閉じ、キャンセルが記録される',
      (tester) async {
        WidgetRef? widgetRef;
        await tester.pumpWidget(
          createTestWidget((context, ref) async {
            widgetRef = ref;
            await VersionUpDialog.show(
              context,
              UpdateRequestType.cancelable,
              ref,
            );
          }),
        );

        // ダイアログ表示ボタンをタップ
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        // ダイアログの外側をタップ
        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();

        // ダイアログが閉じていることを確認
        expect(find.byType(AlertDialog), findsNothing);
        // `clickCancel`が呼ばれたことを確認
        final controller =
            widgetRef!.read(cancelControllerProvider.notifier)
                as TestCancelController;
        expect(controller.clickCancelCalled, isTrue);
      },
    );

    testWidgets('UpdateRequestType.forciblyの場合、強制アップデートダイアログが表示される', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget((context, ref) async {
          await VersionUpDialog.show(context, UpdateRequestType.forcibly, ref);
        }),
      );

      // ダイアログ表示ボタンをタップ
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // ダイアログと各要素が表示されていることを確認
      expect(find.byType(AlertDialog), findsOneWidget);
      // キャンセルボタンが表示されていないことを確認
      expect(find.widgetWithText(TextButton, 'Cancel'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Update'), findsOneWidget);

      // アップデートボタンをタップ
      await tester.tap(find.widgetWithText(TextButton, 'Update'));
      await tester.pumpAndSettle();

      // ダイアログが閉じていることを確認
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
