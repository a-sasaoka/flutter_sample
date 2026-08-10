import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/utils/app_lifecycle_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/data/app_lock_repository.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/app_lock_wrapper.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/passcode_lock_screen.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/passcode_setup_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class _MockAppLockRepository extends Mock implements AppLockRepository {}

class _MockTalker extends Mock implements Talker {}

void main() {
  late _MockAppLockRepository mockRepository;
  late _MockTalker mockTalker;

  setUp(() {
    mockRepository = _MockAppLockRepository();
    mockTalker = _MockTalker();
    when(
      () => mockRepository.isBiometricEnabled(),
    ).thenAnswer((_) async => false);
    when(() => mockRepository.hasPasscode()).thenAnswer((_) async => true);
    when(
      () => mockRepository.authenticateWithBiometrics(
        localizedReason: any(named: 'localizedReason'),
      ),
    ).thenAnswer((_) async => false);
  });

  Widget createTestWidget(
    Widget child, {
    AppLockService Function()? serviceBuilder,
    _TestAppLifecycle Function()? lifecycleBuilder,
  }) {
    return ProviderScope(
      overrides: [
        appLockRepositoryProvider.overrideWithValue(mockRepository),
        loggerProvider.overrideWithValue(mockTalker),
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

    testWidgets(
      '一時非活性 (inactive) のみから復帰 (resumed) した場合は lockApp が呼び出されないこと',
      (tester) async {
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

        // キーボード閉じや通信等に伴う resumed -> inactive -> resumed 遷移
        mockLifecycle.updateLifecycleState(AppLifecycleState.inactive);
        await tester.pump();

        mockLifecycle.updateLifecycleState(AppLifecycleState.resumed);
        await tester.pump();

        expect(mockService.lockAppCalledCount, equals(0));
      },
    );

    testWidgets(
      'バックグラウンド (paused -> inactive -> resumed) の復帰シーケンスで lockApp が呼び出されること',
      (tester) async {
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

        // 真のバックグラウンド paused -> inactive -> resumed 遷移
        mockLifecycle.updateLifecycleState(AppLifecycleState.paused);
        await tester.pump();

        mockLifecycle.updateLifecycleState(AppLifecycleState.inactive);
        await tester.pump();

        mockLifecycle.updateLifecycleState(AppLifecycleState.resumed);
        await tester.pump();

        expect(mockService.lockAppCalledCount, equals(1));
      },
    );

    testWidgets(
      '画面非表示 (hidden -> inactive -> resumed) の復帰シーケンスで lockApp が呼び出されること',
      (tester) async {
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

        // 画面非表示 hidden -> inactive -> resumed 遷移
        mockLifecycle.updateLifecycleState(AppLifecycleState.hidden);
        await tester.pump();

        mockLifecycle.updateLifecycleState(AppLifecycleState.inactive);
        await tester.pump();

        mockLifecycle.updateLifecycleState(AppLifecycleState.resumed);
        await tester.pump();

        expect(mockService.lockAppCalledCount, equals(1));
      },
    );

    testWidgets('loading 状態の時は保護シールド(ColoredBox)が描画される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AppLockWrapper(
            child: Text('Main Screen Content'),
          ),
          serviceBuilder: _LoadingAppLockService.new,
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('app_lock_loading_shield')),
        findsOneWidget,
      );
      expect(find.byType(PasscodeSetupScreen), findsNothing);
      expect(find.byType(PasscodeLockScreen), findsNothing);
    });

    testWidgets('error 状態の時は PasscodeLockScreen にフォールバック描画される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AppLockWrapper(
            child: Text('Main Screen Content'),
          ),
          serviceBuilder: _ErrorAppLockService.new,
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('app_lock_error_fallback')),
        findsOneWidget,
      );
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

class _LoadingAppLockService extends AppLockService {
  @override
  Future<AppLockState> build() {
    return Completer<AppLockState>().future;
  }
}

class _ErrorAppLockService extends AppLockService {
  @override
  Future<AppLockState> build() {
    state = AsyncValue.error(
      Exception('App lock init failed'),
      StackTrace.current,
    );
    return Completer<AppLockState>().future;
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
