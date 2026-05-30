import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLocalizationsX', () {
    testWidgets('l10n returns AppLocalizations when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              // This should not throw
              final l10n = context.l10n;
              return Text(l10n.ok);
            },
          ),
        ),
      );

      check(find.text('OK')).findsOne();
    });

    testWidgets('l10n throws FlutterError when AppLocalizations is not found', (
      tester,
    ) async {
      // Create a widget that calls context.l10n
      // without a Localizations ancestor
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            return Text(context.l10n.ok);
          },
        ),
      );

      final dynamic exception = tester.takeException();
      check(exception).isA<FlutterError>();
      check(
        exception.toString(),
      ).contains('AppLocalizations not found in the current context');
    });
  });
}
