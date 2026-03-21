import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/widgets/not_found_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('NotFoundScreen', () {
    late MockGoRouter mockGoRouter;

    setUp(() {
      mockGoRouter = MockGoRouter();
    });

    Future<void> pumpWidget(WidgetTester tester, {String? unknownPath}) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('ja', ''),
          ],
          home: InheritedGoRouter(
            goRouter: mockGoRouter,
            child: NotFoundScreen(unknownPath: unknownPath),
          ),
        ),
      );
    }

    testWidgets('unknownPathがなくても正しく描画される', (WidgetTester tester) async {
      await pumpWidget(tester);

      expect(find.text('Page Not Found'), findsOneWidget);
      expect(find.text('The page could not be found.'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('unknownPathがあっても正しく描画される', (WidgetTester tester) async {
      const path = '/test_path';
      await pumpWidget(tester, unknownPath: path);

      expect(find.text('Page Not Found'), findsOneWidget);
      expect(find.text('The page could not be found.'), findsOneWidget);
      expect(find.text('path: $path'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('ボタンをタップするとホーム画面に遷移する', (WidgetTester tester) async {
      when(() => mockGoRouter.go('/')).thenAnswer((_) async {});
      await pumpWidget(tester);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      verify(() => mockGoRouter.go('/')).called(1);
    });
  });
}
