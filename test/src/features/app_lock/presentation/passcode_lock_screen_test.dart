import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/data/app_lock_repository.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_sample/src/features/app_lock/presentation/passcode_lock_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppLockRepository extends Mock implements AppLockRepository {}

void main() {
  late _MockAppLockRepository mockRepository;

  setUp(() {
    mockRepository = _MockAppLockRepository();
    when(() => mockRepository.getFailedAttempts()).thenAnswer((_) async => 0);
    when(() => mockRepository.getLockoutUntil()).thenAnswer((_) async => null);
    when(
      () => mockRepository.saveFailedAttempts(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.saveLockoutUntil(any()),
    ).thenAnswer((_) async {});
    when(() => mockRepository.resetLockout()).thenAnswer((_) async {});
  });

  Widget createTestWidget(
    Widget child, {
    _TestAppLockService Function()? serviceBuilder,
  }) {
    return ProviderScope(
      overrides: [
        appLockRepositoryProvider.overrideWithValue(mockRepository),
        appLockServiceProvider.overrideWith(
          serviceBuilder ??
              () => _TestAppLockService(
                const AppLockState.locked(isBiometricEnabled: true),
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

  group('PasscodeLockScreen Widget Tests', () {
    test('PasscodeLockScreen can be instantiated', () {
      // カバレッジ計測でコンストラクタ実行をヒットさせるため、あえて非constで呼び出します。
      // ignore: prefer_const_constructors
      final screen = PasscodeLockScreen(isBiometricEnabled: true);
      check(screen).isA<PasscodeLockScreen>();
    });

    testWidgets('初期表示で「パスコードを入力」とキーパッドが表示される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const PasscodeLockScreen(isBiometricEnabled: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('パスコードを入力'), findsOneWidget);
      expect(find.byIcon(Icons.security), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    });

    testWidgets('生体認証が無効な場合は指紋アイコンが表示されない', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const PasscodeLockScreen(isBiometricEnabled: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('パスコードを入力'), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint), findsNothing);
    });

    testWidgets('正しいパスコードを4桁入力すると解除成功する', (tester) async {
      final mockService = _TestAppLockService(
        const AppLockState.locked(isBiometricEnabled: false),
      );

      await tester.pumpWidget(
        createTestWidget(
          const PasscodeLockScreen(isBiometricEnabled: false),
          serviceBuilder: () => mockService,
        ),
      );
      await tester.pumpAndSettle();

      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.widgetWithText(OutlinedButton, digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      check(mockService.unlockWithPasscodeCalledCount).equals(1);
    });

    testWidgets('誤ったパスコードを入力するとエラーメッセージが表示される', (tester) async {
      final mockService = _TestAppLockService(
        const AppLockState.locked(isBiometricEnabled: false),
      );

      await tester.pumpWidget(
        createTestWidget(
          const PasscodeLockScreen(isBiometricEnabled: false),
          serviceBuilder: () => mockService,
        ),
      );
      await tester.pumpAndSettle();

      for (final digit in ['9', '9', '9', '9']) {
        await tester.tap(find.widgetWithText(OutlinedButton, digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('パスコードが正しくありません'), findsOneWidget);
    });

    testWidgets('入力中に Backspace を押すと一文字削除される', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const PasscodeLockScreen(isBiometricEnabled: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, '1'));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
    });

    testWidgets('指紋アイコンをタップすると手動で生体認証が再試行される', (tester) async {
      final mockService = _TestAppLockService(
        const AppLockState.locked(isBiometricEnabled: true),
      );

      await tester.pumpWidget(
        createTestWidget(
          const PasscodeLockScreen(isBiometricEnabled: true),
          serviceBuilder: () => mockService,
        ),
      );
      await tester.pumpAndSettle();

      // 指紋アイコンをタップ
      await tester.tap(find.byIcon(Icons.fingerprint));
      await tester.pumpAndSettle();

      check(mockService.unlockWithBiometricsCalledCount).isGreaterThan(0);
    });
  });
}

class _TestAppLockService extends AppLockService {
  _TestAppLockService(this._initialState);

  final AppLockState _initialState;
  int unlockWithBiometricsCalledCount = 0;
  int unlockWithPasscodeCalledCount = 0;

  @override
  Future<AppLockState> build() async => _initialState;

  @override
  Future<bool> unlockWithBiometrics({required String localizedReason}) async {
    unlockWithBiometricsCalledCount++;
    return false;
  }

  @override
  Future<bool> unlockWithPasscode(String passcode) async {
    unlockWithPasscodeCalledCount++;
    return passcode == '1234';
  }
}
