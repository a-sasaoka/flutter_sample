import 'package:flutter/material.dart';
import 'package:flutter_sample/src/app/router/snackbar_navigation_observer.dart';
import 'package:flutter_sample/src/core/utils/scaffold_messenger_key.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// [PageRoute] のモッククラス
class MockPageRoute extends Mock implements PageRoute<dynamic> {}

/// [PopupRoute] のモッククラス（ダイアログなどを想定）
class MockPopupRoute extends Mock implements PopupRoute<dynamic> {}

void main() {
  late SnackBarNavigationObserver observer;

  setUp(() {
    observer = SnackBarNavigationObserver(scaffoldMessengerKey);
  });

  group('SnackBarNavigationObserver', () {
    testWidgets('【正常系】didPush の際に PageRoute であれば clearSnackBars が呼ばれること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Test SnackBar')),
      );
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);

      // PageRoute の遷移をシミュレート
      observer.didPush(MockPageRoute(), null);

      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('【正常系】didPop の際に PageRoute であれば clearSnackBars が呼ばれること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Test SnackBar')),
      );
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);

      // PageRoute の遷移をシミュレート
      observer.didPop(MockPageRoute(), null);

      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('【正常系】didReplace の際に PageRoute であれば clearSnackBars が呼ばれること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Test SnackBar')),
      );
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);

      // PageRoute の置換をシミュレート
      observer.didReplace(newRoute: MockPageRoute());

      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('【ガード】PopupRoute（ダイアログ等）の遷移ではスナックバーが消えないこと', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Test SnackBar')),
      );
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);

      // PopupRoute の遷移をシミュレート
      observer.didPush(MockPopupRoute(), null);

      await tester.pump();
      // まだ表示されているはず
      expect(find.byType(SnackBar), findsOneWidget);
    });

    test('currentState が null の場合にエラーにならないこと', () {
      // ダミーのキーを渡して、currentState が null の状態をシミュレート
      final dummyKey = GlobalKey<ScaffoldMessengerState>();
      final dummyObserver = SnackBarNavigationObserver(dummyKey);

      expect(
        () => dummyObserver.didPush(MockPageRoute(), null),
        returnsNormally,
      );
    });
  });
}
