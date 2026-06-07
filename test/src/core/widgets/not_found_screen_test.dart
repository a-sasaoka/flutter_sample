import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/widgets/not_found_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'widgets_test_helper.dart';

void main() {
  group('NotFoundScreen', () {
    late MockGoRouter mockGoRouter;
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockGoRouter = MockGoRouter();
      mockL10n = MockAppLocalizations();

      when(() => mockL10n.notFoundTitle).thenReturn('Page Not Found');
      when(
        () => mockL10n.notFoundMessage,
      ).thenReturn('The page could not be found.');
      when(() => mockL10n.notFoundBackToHome).thenReturn('Back to Home');
    });

    Future<void> pumpWidget(WidgetTester tester, {String? unknownPath}) async {
      // GoRouterのモックをInheritedWidget経由で提供する
      // context.go() などの拡張機能が動作するようにする
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          localizationsDelegates: [
            MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: InheritedGoRouter(
            goRouter: mockGoRouter,
            child: NotFoundScreen(unknownPath: unknownPath),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('unknownPathがなくても正しく描画される', (tester) async {
      await pumpWidget(tester);

      check(find.text('Page Not Found')).findsExactly(2);
      check(find.text('The page could not be found.')).findsOne();
      check(find.text('Back to Home')).findsOne();
      check(find.byIcon(Icons.search_off_outlined)).findsOne();
    });

    testWidgets('unknownPathがあっても正しく描画される', (tester) async {
      const path = '/test_path';
      await pumpWidget(tester, unknownPath: path);

      check(find.text('Page Not Found')).findsExactly(2);
      check(find.text('The page could not be found.')).findsOne();
      check(find.text('path: $path')).findsOne();
      check(find.text('Back to Home')).findsOne();
    });

    testWidgets('ボタンをタップするとホーム画面に遷移する', (tester) async {
      when(() => mockGoRouter.go('/')).thenReturn(null);
      await pumpWidget(tester);

      final button = find.byType(FilledButton);
      await tester.tap(button);
      await tester.pumpAndSettle();

      verify(() => mockGoRouter.go('/')).called(1);
    });
  });
}
