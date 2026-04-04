import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/ui/snackbar_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestApp(void Function(BuildContext) onPressed) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => onPressed(context),
              child: const Text('Show SnackBar'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('showSnackBar displays an info SnackBar by default', (
    WidgetTester tester,
  ) async {
    const testMessage = 'Test Info Message';

    await tester.pumpWidget(
      buildTestApp((context) {
        context.showSnackBar(testMessage);
      }),
    );

    // Tap to show SnackBar
    await tester.tap(find.text('Show SnackBar'));
    await tester.pumpAndSettle(); // Wait for animation to finish

    // Verify SnackBar appears
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(testMessage), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(
      find.text('Close'),
      findsOneWidget,
    ); // Close text from AppLocalizations

    // Verify background color
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, Colors.grey.shade800);

    // Tap 'Close' action to dismiss
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // Verify SnackBar is dismissed
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('showSuccessSnackBar displays a success SnackBar', (
    WidgetTester tester,
  ) async {
    const testMessage = 'Test Success Message';

    await tester.pumpWidget(
      buildTestApp((context) {
        context.showSuccessSnackBar(testMessage);
      }),
    );

    await tester.tap(find.text('Show SnackBar'));
    await tester.pump();

    // Verify success specific elements
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(testMessage), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, Colors.green.shade700);
  });

  testWidgets('showErrorSnackBar displays an error SnackBar', (
    WidgetTester tester,
  ) async {
    const testMessage = 'Test Error Message';

    await tester.pumpWidget(
      buildTestApp((context) {
        context.showErrorSnackBar(testMessage);
      }),
    );

    await tester.tap(find.text('Show SnackBar'));
    await tester.pump();

    // Verify error specific elements
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(testMessage), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, Colors.red.shade700);
  });

  testWidgets(
    'showSnackBar hides the previous SnackBar if called consecutively',
    (WidgetTester tester) async {
      const message1 = 'Message 1';
      const message2 = 'Message 2';

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ElevatedButton(
                      key: const Key('btn1'),
                      onPressed: () => context.showSnackBar(message1),
                      child: const Text('Btn 1'),
                    ),
                    ElevatedButton(
                      key: const Key('btn2'),
                      onPressed: () => context.showSnackBar(message2),
                      child: const Text('Btn 2'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Tap first button
      await tester.tap(find.byKey(const Key('btn1')));
      await tester.pump();
      expect(find.text(message1), findsOneWidget);

      // Tap second button immediately
      await tester.tap(find.byKey(const Key('btn2')));
      await tester
          .pump(); // Start hide animation for first, show animation for second

      // Process animations
      await tester.pumpAndSettle();

      // First message should be removed, second should be visible
      expect(find.text(message1), findsNothing);
      expect(find.text(message2), findsOneWidget);
    },
  );
}
