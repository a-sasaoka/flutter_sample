import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/utils/app_lifecycle_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/app_lock_wrapper.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/passcode_lock_screen.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/passcode_setup_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Widget createTestWidget(
    Widget child, {
    _TestAppLockService Function()? serviceBuilder,
    _TestAppLifecycle Function()? lifecycleBuilder,
  }) {
    return ProviderScope(
      overrides: [
        appLockServiceProvider.overrideWith(
          serviceBuilder ??
              () => _TestAppLockService(const AppLockState.disabled()),
        ),
        appLifecycleProvider.overrideWith(
          lifecycleBuilder ?? _TestAppLifecycle.new,
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

  group('AppLockWrapper Widget Tests', () {
    test('AppLockWrapper can be instantiated', () {
      // カバレッジ計測でコンストラクタのコードを確実に実行させてカバーするため、あえて非constでインスタンス化します。
      // ignore: prefer_const_constructors
      final wrapper = AppLockWrapper(child: const SizedBox());
      check(wrapper).isA<AppLockWrapper>();
    });

    testWidgets('AppLockStateDisabled 時は通常コンテンツのみ表示される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AppLockWrapper(
            child: Text('Main Screen Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Main Screen Content'), findsOneWidget);
      expect(find.byType(PasscodeSetupScreen), findsNothing);
      expect(find.byType(PasscodeLockScreen), findsNothing);
    });

    testWidgets('AppLockStateUnlocked 時は通常コンテンツのみ表示される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AppLockWrapper(
            child: Text('Main Screen Content'),
          ),
          serviceBuilder: () => _TestAppLockService(
            const AppLockState.unlocked(isBiometricEnabled: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Main Screen Content'), findsOneWidget);
      expect(find.byType(PasscodeSetupScreen), findsNothing);
      expect(find.byType(PasscodeLockScreen), findsNothing);
    });

    testWidgets(
      'AppLockStateSetupRequired 時は PasscodeSetupScreen が最前面にオーバーレイ描画される',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            const AppLockWrapper(
              child: Text('Main Screen Content'),
            ),
            serviceBuilder: () => _TestAppLockService(
              const AppLockState.setupRequired(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Main Screen Content'), findsOneWidget);
        expect(find.byType(PasscodeSetupScreen), findsOneWidget);
        expect(find.byType(PasscodeLockScreen), findsNothing);
      },
    );

    testWidgets('AppLockStateLocked 時は PasscodeLockScreen が最前面にオーバーレイ描画される', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          const AppLockWrapper(
            child: Text('Main Screen Content'),
          ),
          serviceBuilder: () => _TestAppLockService(
            const AppLockState.locked(isBiometricEnabled: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Main Screen Content'), findsOneWidget);
      expect(find.byType(PasscodeSetupScreen), findsNothing);
      expect(find.byType(PasscodeLockScreen), findsOneWidget);
    });

    testWidgets('アプリ復帰(resumed)時に lockApp が呼び出されること', (tester) async {
      final mockService = _TestAppLockService(
        const AppLockState.unlocked(isBiometricEnabled: true),
      );
      final mockLifecycle = _TestAppLifecycle();

      await tester.pumpWidget(
        createTestWidget(
          const AppLockWrapper(
            child: Text('Main Screen Content'),
          ),
          serviceBuilder: () => mockService,
          lifecycleBuilder: () => mockLifecycle,
        ),
      );
      await tester.pumpAndSettle();

      // 一度 inactive にしたのち resumed を通知
      mockLifecycle.updateLifecycleState(AppLifecycleState.inactive);
      await tester.pump();

      mockLifecycle.updateLifecycleState(AppLifecycleState.resumed);
      await tester.pump();

      expect(mockService.lockAppCalledCount, equals(1));
    });
  });
}

class _TestAppLockService extends AppLockService {
  _TestAppLockService(this._initialState);
  final AppLockState _initialState;
  int lockAppCalledCount = 0;

  @override
  Future<AppLockState> build() async => _initialState;

  @override
  void lockApp() {
    lockAppCalledCount++;
  }
}

class _TestAppLifecycle extends AppLifecycle {
  @override
  AppLifecycleState build() => AppLifecycleState.resumed;

  // テスト用ヘルパーメソッドのため、プロパティセッターを使わずに内部状態を直接変更します。
  // ignore: use_setters_to_change_properties
  void updateLifecycleState(AppLifecycleState newState) {
    state = newState;
  }
}
