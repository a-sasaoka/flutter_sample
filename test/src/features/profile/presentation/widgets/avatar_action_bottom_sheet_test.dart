import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/profile/presentation/widgets/avatar_action_bottom_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createTestWidget({
    required Widget child,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja')],
      locale: const Locale('ja'),
      home: Scaffold(body: child),
    );
  }

  group('AvatarActionBottomSheet Widget Tests', () {
    testWidgets(
      'hasAvatar: false の場合、カメラとアルバムの選択肢が表示され、削除ボタンは非表示であること',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            child: const AvatarActionBottomSheet(hasAvatar: false),
          ),
        );
        await tester.pumpAndSettle();

        check(find.text('アイコン写真の変更')).findsOne();
        check(find.text('カメラで撮影')).findsOne();
        check(find.text('アルバムから選択')).findsOne();
        check(find.text('現在の写真を削除')).findsNothing();
      },
    );

    testWidgets('hasAvatar: true の場合、削除ボタンも表示されること', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const AvatarActionBottomSheet(hasAvatar: true),
        ),
      );
      await tester.pumpAndSettle();

      check(find.text('アイコン写真の変更')).findsOne();
      check(find.text('カメラで撮影')).findsOne();
      check(find.text('アルバムから選択')).findsOne();
      check(find.text('現在の写真を削除')).findsOne();
    });

    testWidgets(
      '「カメラで撮影」をタップした時、AvatarActionType.camera が返ること',
      (tester) async {
        AvatarActionType? selectedAction;

        await tester.pumpWidget(
          createTestWidget(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedAction = await AvatarActionBottomSheet.show(
                    context,
                    hasAvatar: false,
                  );
                },
                child: const Text('開く'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ボトムシートを開く
        await tester.tap(find.text('開く'));
        await tester.pumpAndSettle();

        // カメラをタップ
        await tester.tap(find.text('カメラで撮影'));
        await tester.pumpAndSettle();

        check(selectedAction).equals(AvatarActionType.camera);
      },
    );

    testWidgets(
      '「アルバムから選択」をタップした時、AvatarActionType.gallery が返ること',
      (tester) async {
        AvatarActionType? selectedAction;

        await tester.pumpWidget(
          createTestWidget(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedAction = await AvatarActionBottomSheet.show(
                    context,
                    hasAvatar: false,
                  );
                },
                child: const Text('開く'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ボトムシートを開く
        await tester.tap(find.text('開く'));
        await tester.pumpAndSettle();

        // アルバムをタップ
        await tester.tap(find.text('アルバムから選択'));
        await tester.pumpAndSettle();

        check(selectedAction).equals(AvatarActionType.gallery);
      },
    );

    testWidgets('「現在の写真を削除」をタップした時、AvatarActionType.delete が返ること', (
      tester,
    ) async {
      AvatarActionType? selectedAction;

      await tester.pumpWidget(
        createTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedAction = await AvatarActionBottomSheet.show(
                  context,
                  hasAvatar: true,
                );
              },
              child: const Text('開く'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ボトムシートを開く
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      // 削除をタップ
      await tester.tap(find.text('現在の写真を削除'));
      await tester.pumpAndSettle();

      check(selectedAction).equals(AvatarActionType.delete);
    });
  });
}
