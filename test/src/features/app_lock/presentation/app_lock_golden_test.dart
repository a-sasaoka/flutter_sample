import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/passcode_lock_screen.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/passcode_setup_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('AppLock Golden Tests', () {
    Widget buildAppLockScreenForGolden({
      required Widget child,
      required ThemeMode themeMode,
      AppLockState initialState = const AppLockState.disabled(),
    }) {
      final isDark = themeMode == ThemeMode.dark;
      return ProviderScope(
        overrides: [
          appLockServiceProvider.overrideWith(
            () => _TestAppLockService(initialState),
          ),
        ],
        child: MaterialApp(
          theme: isDark
              ? AppTheme.dark().copyWith(
                  textTheme: AppTheme.dark().textTheme.apply(
                    fontFamily: 'NotoSansJP',
                  ),
                )
              : AppTheme.light().copyWith(
                  textTheme: AppTheme.light().textTheme.apply(
                    fontFamily: 'NotoSansJP',
                  ),
                ),
          themeMode: themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ja')],
          home: child,
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // ignore: discarded_futures, alchemist golden test runner handles futures
    goldenTest(
      'PasscodeSetupScreen の描画 (ライト/ダークモード)',
      fileName: 'passcode_setup_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildAppLockScreenForGolden(
                child: const PasscodeSetupScreen(),
                themeMode: ThemeMode.light,
                initialState: const AppLockState.setupRequired(),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildAppLockScreenForGolden(
                child: const PasscodeSetupScreen(),
                themeMode: ThemeMode.dark,
                initialState: const AppLockState.setupRequired(),
              ),
            ),
          ),
        ],
      ),
    );

    // ignore: discarded_futures, alchemist golden test runner handles futures
    goldenTest(
      'PasscodeLockScreen の描画 (ライト/ダークモード)',
      fileName: 'passcode_lock_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode - Biometrics Enabled',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildAppLockScreenForGolden(
                child: const PasscodeLockScreen(isBiometricEnabled: true),
                themeMode: ThemeMode.light,
                initialState: const AppLockState.locked(
                  isBiometricEnabled: true,
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode - Biometrics Disabled',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildAppLockScreenForGolden(
                child: const PasscodeLockScreen(isBiometricEnabled: false),
                themeMode: ThemeMode.dark,
                initialState: const AppLockState.locked(
                  isBiometricEnabled: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}

class _TestAppLockService extends AppLockService {
  _TestAppLockService(this._initialState);

  final AppLockState _initialState;

  @override
  Future<AppLockState> build() async => _initialState;

  @override
  Future<bool> setupPasscode(String passcode) async => false;

  @override
  Future<void> skipBiometric() async {}

  @override
  Future<bool> enableBiometric({required String localizedReason}) async =>
      false;

  @override
  Future<UnlockResult> unlockWithPasscode(String passcode) async =>
      const UnlockResultInvalidPasscode();

  @override
  Future<bool> unlockWithBiometrics({
    required String localizedReason,
  }) async => false;
}
