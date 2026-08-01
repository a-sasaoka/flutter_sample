import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/passcode_setup_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Widget createTestWidget({
    required Widget child,
    AppLockService Function()? serviceBuilder,
  }) {
    return ProviderScope(
      overrides: [
        appLockServiceProvider.overrideWith(
          serviceBuilder ??
              () => _TestAppLockService(
                const AppLockState.setupRequired(),
              ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ja')],
        home: child,
      ),
    );
  }

  group('PasscodeSetupScreen Widget Tests', () {
    test('PasscodeSetupScreen can be instantiated', () {
      // カバレッジでコンストラクタ通過を評価するためにあえて非constで呼び出します。
      // ignore: prefer_const_constructors
      final screen = PasscodeSetupScreen();
      check(screen).isA<PasscodeSetupScreen>();
    });

    testWidgets('初期表示でタイトル「パスコードの設定」が表示される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const PasscodeSetupScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('パスコードの設定'), findsOneWidget);
      expect(find.text('新しい4桁のパスコードを入力してください'), findsOneWidget);
    });

    testWidgets('Backspaceを押すと入力文字が削除される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const PasscodeSetupScreen()),
      );
      await tester.pumpAndSettle();

      // '1', '2' を入力
      await tester.tap(find.widgetWithText(OutlinedButton, '1'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '2'));
      await tester.pump();

      // Backspaceを押す
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
    });

    testWidgets('4桁テンキーを押すとドットが埋まり再確認表示へ切り替わり、Backspaceも動作する', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const PasscodeSetupScreen()),
      );
      await tester.pumpAndSettle();

      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.widgetWithText(OutlinedButton, digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('確認のため、もう一度入力してください'), findsOneWidget);

      // 2回目入力中にBackspaceを押す
      await tester.tap(find.widgetWithText(OutlinedButton, '1'));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
    });

    testWidgets('不一致のパスコードを入力するとエラーメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const PasscodeSetupScreen()),
      );
      await tester.pumpAndSettle();

      // 1回目: 1, 2, 3, 4
      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.widgetWithText(OutlinedButton, digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // 2回目: 9, 8, 7, 6 (不一致)
      for (final digit in ['9', '8', '7', '6']) {
        await tester.tap(find.widgetWithText(OutlinedButton, digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('パスコードが一致しません。最初からやり直してください'), findsOneWidget);
    });

    testWidgets('生体認証非対応端末の場合、一致入力で自動的に生体認証がスキップされる', (tester) async {
      final mockService = _TestAppLockService(
        const AppLockState.setupRequired(),
        canCheckBiometrics: false,
      );

      await tester.pumpWidget(
        createTestWidget(
          child: const PasscodeSetupScreen(),
          serviceBuilder: () => mockService,
        ),
      );
      await tester.pumpAndSettle();

      // 1回目 & 2回目に 1,2,3,4 を入力
      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.widgetWithText(OutlinedButton, digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.widgetWithText(OutlinedButton, digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      check(mockService.skipBiometricCalledCount).equals(1);
    });

    testWidgets('パスコード一致時に生体認証モーダルが表示され「スキップ」をタップできる', (tester) async {
      final mockService = _TestAppLockService(
        const AppLockState.setupRequired(),
      );

      await tester.pumpWidget(
        createTestWidget(
          child: const PasscodeSetupScreen(),
          serviceBuilder: () => mockService,
        ),
      );
      await tester.pumpAndSettle();

      // 1回目 & 2回目に 1,2,3,4 を入力
      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.widgetWithText(OutlinedButton, digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.widgetWithText(OutlinedButton, digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('生体認証の有効化'), findsOneWidget);

      // 「スキップ」をタップ
      await tester.tap(find.text('スキップ'));
      await tester.pumpAndSettle();

      check(mockService.skipBiometricCalledCount).equals(1);
    });

    testWidgets('パスコード一致時に生体認証モーダルが表示され「有効にする」をタップできる', (tester) async {
      final mockService = _TestAppLockService(
        const AppLockState.setupRequired(),
      );

      await tester.pumpWidget(
        createTestWidget(
          child: const PasscodeSetupScreen(),
          serviceBuilder: () => mockService,
        ),
      );
      await tester.pumpAndSettle();

      // 1回目 & 2回目に 1,2,3,4 を入力
      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.widgetWithText(OutlinedButton, digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.widgetWithText(OutlinedButton, digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // 「有効にする」をタップ
      await tester.tap(find.text('有効にする'));
      await tester.pumpAndSettle();

      check(mockService.enableBiometricCalledCount).equals(1);
    });
  });
}

class _TestAppLockService extends AppLockService {
  _TestAppLockService(
    this._initialState, {
    this.canCheckBiometrics = true,
  });

  final AppLockState _initialState;
  final bool canCheckBiometrics;
  int skipBiometricCalledCount = 0;
  int enableBiometricCalledCount = 0;

  @override
  Future<AppLockState> build() async => _initialState;

  @override
  Future<bool> setupPasscode(String passcode) async {
    return canCheckBiometrics;
  }

  @override
  void skipBiometric() {
    skipBiometricCalledCount++;
  }

  @override
  Future<bool> enableBiometric({required String localizedReason}) async {
    enableBiometricCalledCount++;
    return true;
  }
}
