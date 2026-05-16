import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/widgets/not_found_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouter extends Mock implements GoRouter {}

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
  bool shouldReload(covariant _) => false;
}

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
            _MockLocalizationsDelegate(mockL10n),
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

      expect(find.text('Page Not Found'), findsNWidgets(2));
      expect(find.text('The page could not be found.'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
    });

    testWidgets('unknownPathがあっても正しく描画される', (tester) async {
      const path = '/test_path';
      await pumpWidget(tester, unknownPath: path);

      expect(find.text('Page Not Found'), findsNWidgets(2));
      expect(find.text('The page could not be found.'), findsOneWidget);
      expect(find.text('path: $path'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
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
