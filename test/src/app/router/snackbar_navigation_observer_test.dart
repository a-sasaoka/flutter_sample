import 'package:flutter/material.dart';
import 'package:flutter_sample/src/app/router/snackbar_navigation_observer.dart';
import 'package:flutter_sample/src/core/utils/scaffold_messenger_key.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// [Route] のモッククラス
class MockRoute extends Mock implements Route<dynamic> {}

void main() {
  late SnackBarNavigationObserver observer;

  setUp(() {
    observer = SnackBarNavigationObserver();

    // グローバルキーをテストごとにリセット、またはモックの状態を注入
    // 実際にはGlobalKeyの中身を直接差し替えるのは難しいため、
    // テスト用のウィジェットツリーで key を使用して挙動を確認する
  });

  group('SnackBarNavigationObserver', () {
    testWidgets('didPush の際に clearSnackBars が呼ばれること', (tester) async {
      // 1. テスト用のアプリを構築し、scaffoldMessengerKey を紐付ける
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      // 2. スナックバーを表示（表示されることを確認）
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Test SnackBar')),
      );
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);

      // 3. Observer を通じて didPush をシミュレート
      observer.didPush(MockRoute(), null);

      // 4. スナックバーが消えていることを確認
      // clearSnackBars は即座に消えるため、pump で反映
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('didPop の際に clearSnackBars が呼ばれること', (tester) async {
      // 1. テスト用のアプリを構築
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      // 2. スナックバーを表示
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Test SnackBar')),
      );
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);

      // 3. Observer を通じて didPop をシミュレート
      observer.didPop(MockRoute(), null);

      // 4. スナックバーが消えていることを確認
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
    });

    test('currentState が null の場合にエラーにならないこと', () {
      // キーに何も紐付いていない状態（currentState が null）で呼び出しても
      // クラッシュしないことを確認（カバレッジのため）

      // 注意: グローバルキーは static に近い性質を持つため、
      // 以前のテストで MaterialApp に紐付いている可能性がある。
      // ここでは明示的な検証は難しいが、コードパスを通す。
      observer
        ..didPush(MockRoute(), null)
        ..didPop(MockRoute(), null);
    });
  });
}
