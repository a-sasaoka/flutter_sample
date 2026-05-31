import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/ui/snackbar_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = ThemeData(useMaterial3: true);

  Widget buildTestApp(void Function(BuildContext) onPressed) {
    return MaterialApp(
      theme: theme,
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
    tester,
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
    check(find.byType(SnackBar)).findsOne();
    check(find.text(testMessage)).findsOne();
    check(find.byIcon(Icons.info_outline)).findsOne();
    check(find.text('Close')).findsOne(); // Close text from AppLocalizations

    // Verify background color
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    check(
      snackBar.backgroundColor,
    ).equals(theme.colorScheme.secondaryContainer);

    // Tap 'Close' action to dismiss
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // Verify SnackBar is dismissed
    check(find.byType(SnackBar)).findsNothing();
  });

  testWidgets('showSuccessSnackBar displays a success SnackBar', (
    tester,
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
    check(find.byType(SnackBar)).findsOne();
    check(find.text(testMessage)).findsOne();
    check(find.byIcon(Icons.check_circle_outline)).findsOne();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    check(snackBar.backgroundColor).equals(theme.colorScheme.primaryContainer);
  });

  testWidgets('showErrorSnackBar displays an error SnackBar', (
    tester,
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
    check(find.byType(SnackBar)).findsOne();
    check(find.text(testMessage)).findsOne();
    check(find.byIcon(Icons.error_outline)).findsOne();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    check(snackBar.backgroundColor).equals(theme.colorScheme.errorContainer);
  });

  testWidgets(
    'showSnackBar hides the previous SnackBar if called consecutively',
    (tester) async {
      const message1 = 'Message 1';
      const message2 = 'Message 2';

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
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
      check(find.text(message1)).findsOne();

      // Tap second button immediately
      await tester.tap(find.byKey(const Key('btn2')));
      await tester
          .pump(); // Start hide animation for first, show animation for second

      // Process animations
      await tester.pumpAndSettle();

      // First message should be removed, second should be visible
      check(find.text(message1)).findsNothing();
      check(find.text(message2)).findsOne();
    },
  );
}
