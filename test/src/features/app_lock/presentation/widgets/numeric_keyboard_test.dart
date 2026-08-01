import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/widgets/numeric_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NumericKeyboard Unit & Widget Tests', () {
    test('NumericKeyboard can be instantiated', () {
      final keyboard = NumericKeyboard(
        onNumberPressed: (_) {},
        onBackspacePressed: () {},
      );
      check(keyboard).isA<NumericKeyboard>();
    });

    testWidgets('数字ボタンをタップすると onNumberPressed が正しく呼ばれる', (tester) async {
      String? pressedNumber;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumericKeyboard(
              onNumberPressed: (number) => pressedNumber = number,
              onBackspacePressed: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, '5'));
      await tester.pump();

      check(pressedNumber).equals('5');
    });

    testWidgets('Backspaceボタンをタップすると onBackspacePressed が呼ばれる', (tester) async {
      var backspaceCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumericKeyboard(
              onNumberPressed: (_) {},
              onBackspacePressed: () => backspaceCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      check(backspaceCalled).isTrue();
    });

    testWidgets('生体認証ボタンをタップすると onBiometricPressed が呼ばれる', (tester) async {
      var biometricCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumericKeyboard(
              onNumberPressed: (_) {},
              onBackspacePressed: () {},
              onBiometricPressed: () => biometricCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.fingerprint));
      await tester.pump();

      check(biometricCalled).isTrue();
    });
  });
}
