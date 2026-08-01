import 'package:checks/checks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/data/app_lock_repository.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockAppLockRepository extends Mock implements AppLockRepository {}

class MockTalker extends Mock implements Talker {}

class MockUser extends Mock implements User {}

void main() {
  late MockAppLockRepository mockRepository;
  late MockTalker mockTalker;

  setUp(() {
    mockRepository = MockAppLockRepository();
    mockTalker = MockTalker();
  });

  ProviderContainer createContainer({
    required bool isAuthenticated,
    required bool hasPasscode,
    required bool isBiometricEnabled,
    bool useFirebaseAuth = false,
    User? firebaseUser,
    DateTime Function()? clock,
  }) {
    var failedAttempts = 0;
    DateTime? lockoutUntil;

    when(
      () => mockRepository.getFailedAttempts(),
    ).thenAnswer((_) async => failedAttempts);
    when(
      () => mockRepository.saveFailedAttempts(any()),
    ).thenAnswer((invocation) async {
      failedAttempts = invocation.positionalArguments[0] as int;
    });
    when(
      () => mockRepository.getLockoutUntil(),
    ).thenAnswer((_) async => lockoutUntil);
    when(
      () => mockRepository.saveLockoutUntil(any()),
    ).thenAnswer((invocation) async {
      lockoutUntil = invocation.positionalArguments[0] as DateTime?;
    });
    when(() => mockRepository.resetLockout()).thenAnswer((_) async {
      failedAttempts = 0;
      lockoutUntil = null;
    });
    when(
      () => mockRepository.hasPasscode(),
    ).thenAnswer((_) async => hasPasscode);
    when(
      () => mockRepository.isBiometricEnabled(),
    ).thenAnswer((_) async => isBiometricEnabled);

    final container = ProviderContainer(
      overrides: [
        appLockRepositoryProvider.overrideWithValue(mockRepository),
        loggerProvider.overrideWithValue(mockTalker),
        if (clock != null) clockProvider.overrideWithValue(clock),
        envConfigProvider.overrideWithValue(
          EnvConfigState(
            baseUrl: 'http://example.com',
            aiModel: 'gemini-2.5-flash',
            connectTimeout: 10,
            receiveTimeout: 15,
            sendTimeout: 10,
            useFirebaseAuth: useFirebaseAuth,
          ),
        ),
        authStateProvider.overrideWith(
          () => _TestAuthStateNotifier(isAuthenticated: isAuthenticated),
        ),
        firebaseAuthStateProvider.overrideWith(
          () => _TestFirebaseAuthStateNotifier(firebaseUser),
        ),
      ],
    );

    // テスト用にプロバイダーの生存を維持するため初期監視を行います。
    // ignore: cascade_invocations
    container.listen(appLockServiceProvider, (previous, next) {});
    addTearDown(container.dispose);
    return container;
  }

  group('AppLockService Build & Initialization Tests', () {
    test('build: 未ログイン状態の場合は AppLockState.disabled を返す', () async {
      final container = createContainer(
        isAuthenticated: false,
        hasPasscode: false,
        isBiometricEnabled: false,
      );

      final state = await container.read(appLockServiceProvider.future);

      check(state).equals(const AppLockState.disabled());
    });

    test('build: Firebase Auth 利用時、未ログインの場合は disabled を返す', () async {
      final container = createContainer(
        isAuthenticated: false,
        hasPasscode: false,
        isBiometricEnabled: false,
        useFirebaseAuth: true,
      );

      final state = await container.read(appLockServiceProvider.future);

      check(state).equals(const AppLockState.disabled());
    });

    test('build: Firebase Auth 利用時、ログイン中の場合は setupRequired を返す', () async {
      final mockUser = MockUser();
      final container = createContainer(
        isAuthenticated: false,
        hasPasscode: false,
        isBiometricEnabled: false,
        useFirebaseAuth: true,
        firebaseUser: mockUser,
      );

      final state = await container.read(appLockServiceProvider.future);

      check(state).equals(const AppLockState.setupRequired());
    });

    test('build: ログイン中でパスコード未設定の場合は AppLockState.setupRequired を返す', () async {
      final container = createContainer(
        isAuthenticated: true,
        hasPasscode: false,
        isBiometricEnabled: false,
      );

      final state = await container.read(appLockServiceProvider.future);

      check(state).equals(const AppLockState.setupRequired());
    });

    test('build: ログイン中でパスコード設定済みの場合は AppLockState.locked を返す', () async {
      final container = createContainer(
        isAuthenticated: true,
        hasPasscode: true,
        isBiometricEnabled: true,
      );

      final state = await container.read(appLockServiceProvider.future);

      check(state).equals(
        const AppLockState.locked(isBiometricEnabled: true),
      );
    });
  });

  group('AppLockService Action Methods Tests', () {
    test('setupPasscode: パスコードを保存し生体認証可能判定を返す', () async {
      final container = createContainer(
        isAuthenticated: true,
        hasPasscode: false,
        isBiometricEnabled: false,
      );
      await container.read(appLockServiceProvider.future);

      when(() => mockRepository.savePasscode('1234')).thenAnswer((_) async {});
      when(
        () => mockRepository.canCheckBiometrics(),
      ).thenAnswer((_) async => true);

      final canCheck = await container
          .read(appLockServiceProvider.notifier)
          .setupPasscode('1234');

      check(canCheck).equals(true);
      verify(() => mockRepository.savePasscode('1234')).called(1);
      verify(() => mockRepository.canCheckBiometrics()).called(1);
    });

    test('skipBiometric: 生体認証をスキップして unlocked 状態に移行する', () async {
      final container = createContainer(
        isAuthenticated: true,
        hasPasscode: false,
        isBiometricEnabled: false,
      );
      await container.read(appLockServiceProvider.future);

      container.read(appLockServiceProvider.notifier).skipBiometric();

      final state = container.read(appLockServiceProvider).value;
      check(state).equals(
        const AppLockState.unlocked(isBiometricEnabled: false),
      );
    });

    test('enableBiometric: 生体認証成功時は有効化して unlocked 状態に移行する', () async {
      final container = createContainer(
        isAuthenticated: true,
        hasPasscode: false,
        isBiometricEnabled: false,
      );
      await container.read(appLockServiceProvider.future);

      when(
        () => mockRepository.authenticateWithBiometrics(
          localizedReason: 'Reason',
        ),
      ).thenAnswer((_) async => true);
      when(
        () => mockRepository.setBiometricEnabled(enabled: true),
      ).thenAnswer((_) async {});

      final result = await container
          .read(appLockServiceProvider.notifier)
          .enableBiometric(localizedReason: 'Reason');

      check(result).equals(true);
      final state = container.read(appLockServiceProvider).value;
      check(state).equals(
        const AppLockState.unlocked(isBiometricEnabled: true),
      );
      verify(() => mockRepository.setBiometricEnabled(enabled: true)).called(1);
    });

    test('enableBiometric: 生体認証キャンセル時は無効化のまま unlocked 状態に移行する', () async {
      final container = createContainer(
        isAuthenticated: true,
        hasPasscode: false,
        isBiometricEnabled: false,
      );
      await container.read(appLockServiceProvider.future);

      when(
        () => mockRepository.authenticateWithBiometrics(
          localizedReason: 'Reason',
        ),
      ).thenAnswer((_) async => false);
      when(
        () => mockRepository.setBiometricEnabled(enabled: false),
      ).thenAnswer((_) async {});

      final result = await container
          .read(appLockServiceProvider.notifier)
          .enableBiometric(localizedReason: 'Reason');

      check(result).equals(false);
      final state = container.read(appLockServiceProvider).value;
      check(state).equals(
        const AppLockState.unlocked(isBiometricEnabled: false),
      );
      verify(
        () => mockRepository.setBiometricEnabled(enabled: false),
      ).called(1);
    });

    test('unlockWithPasscode: 正しいパスコードでロック解除に成功する', () async {
      final container = createContainer(
        isAuthenticated: true,
        hasPasscode: true,
        isBiometricEnabled: false,
      );
      await container.read(appLockServiceProvider.future);

      when(
        () => mockRepository.verifyPasscode('1234'),
      ).thenAnswer((_) async => true);

      final result = await container
          .read(appLockServiceProvider.notifier)
          .unlockWithPasscode('1234');

      check(result).isA<UnlockResultSuccess>();
      final state = container.read(appLockServiceProvider).value;
      check(state).equals(
        const AppLockState.unlocked(isBiometricEnabled: false),
      );
    });

    test('unlockWithPasscode: 誤ったパスコードの場合はロック維持される', () async {
      final container = createContainer(
        isAuthenticated: true,
        hasPasscode: true,
        isBiometricEnabled: false,
      );
      await container.read(appLockServiceProvider.future);

      when(
        () => mockRepository.verifyPasscode('9999'),
      ).thenAnswer((_) async => false);

      final result = await container
          .read(appLockServiceProvider.notifier)
          .unlockWithPasscode('9999');

      check(result).isA<UnlockResultInvalidPasscode>();
      final state = container.read(appLockServiceProvider).value;
      check(state).equals(
        const AppLockState.locked(isBiometricEnabled: false),
      );
    });

    test(
      'unlockWithPasscode: 3回連続失敗で30秒ロックアウトが発動し、 '
      'さらに失敗すると指数関数的(60秒)にロックアウトが延長される',
      () async {
        var currentTime = DateTime(2026, 8, 1, 12);
        final container = createContainer(
          isAuthenticated: true,
          hasPasscode: true,
          isBiometricEnabled: false,
          clock: () => currentTime,
        );
        await container.read(appLockServiceProvider.future);

        when(
          () => mockRepository.verifyPasscode('9999'),
        ).thenAnswer((_) async => false);

        // 1回目、2回目失敗
        check(
          await container
              .read(appLockServiceProvider.notifier)
              .unlockWithPasscode('9999'),
        ).isA<UnlockResultInvalidPasscode>();
        check(
          await container
              .read(appLockServiceProvider.notifier)
              .unlockWithPasscode('9999'),
        ).isA<UnlockResultInvalidPasscode>();

        verify(() => mockRepository.verifyPasscode('9999')).called(2);

        // 3回目失敗 (初回ロックアウト発動: 30秒)
        check(
          await container
              .read(appLockServiceProvider.notifier)
              .unlockWithPasscode('9999'),
        ).isA<UnlockResultLockedOut>();
        verify(() => mockRepository.verifyPasscode('9999')).called(1);

        // ロックアウト期間中 (10秒後) は verifyPasscode を呼ぶことなく即座に拒否される
        currentTime = currentTime.add(const Duration(seconds: 10));
        check(
          await container
              .read(appLockServiceProvider.notifier)
              .unlockWithPasscode('1234'),
        ).isA<UnlockResultLockedOut>();

        // 追加の verifyPasscode は呼ばれていないことを検証
        verifyNever(() => mockRepository.verifyPasscode('1234'));

        // 31秒経過後はロックアウトが一度解除されるが、さらに失敗(4回目失敗)すると指数バックオフで60秒間ロックアウト
        currentTime = currentTime.add(const Duration(seconds: 21));
        check(
          await container
              .read(appLockServiceProvider.notifier)
              .unlockWithPasscode('9999'),
        ).isA<UnlockResultLockedOut>();

        // 60秒のロックアウト期間中 (30秒経過時) は拒否される
        currentTime = currentTime.add(const Duration(seconds: 30));
        check(
          await container
              .read(appLockServiceProvider.notifier)
              .unlockWithPasscode('1234'),
        ).isA<UnlockResultLockedOut>();

        // 61秒経過後は解除され、正しいパスコードで成功・カウンターがリセットされる
        currentTime = currentTime.add(const Duration(seconds: 31));
        when(
          () => mockRepository.verifyPasscode('1234'),
        ).thenAnswer((_) async => true);

        check(
          await container
              .read(appLockServiceProvider.notifier)
              .unlockWithPasscode('1234'),
        ).isA<UnlockResultSuccess>();

        final state = container.read(appLockServiceProvider).value;
        check(state).equals(
          const AppLockState.unlocked(isBiometricEnabled: false),
        );
      },
    );

    test('unlockWithBiometrics: 生体認証成功でロック解除される', () async {
      final container = createContainer(
        isAuthenticated: true,
        hasPasscode: true,
        isBiometricEnabled: true,
      );
      await container.read(appLockServiceProvider.future);

      when(
        () => mockRepository.authenticateWithBiometrics(
          localizedReason: 'Reason',
        ),
      ).thenAnswer((_) async => true);

      final result = await container
          .read(appLockServiceProvider.notifier)
          .unlockWithBiometrics(localizedReason: 'Reason');

      check(result).equals(true);
      final state = container.read(appLockServiceProvider).value;
      check(state).equals(
        const AppLockState.unlocked(isBiometricEnabled: true),
      );
    });

    test('unlockWithBiometrics: 認証失敗時は false を返しロック維持される', () async {
      final container = createContainer(
        isAuthenticated: true,
        hasPasscode: true,
        isBiometricEnabled: true,
      );
      await container.read(appLockServiceProvider.future);

      when(
        () => mockRepository.authenticateWithBiometrics(
          localizedReason: 'Reason',
        ),
      ).thenAnswer((_) async => false);

      final result = await container
          .read(appLockServiceProvider.notifier)
          .unlockWithBiometrics(localizedReason: 'Reason');

      check(result).equals(false);
      final state = container.read(appLockServiceProvider).value;
      check(state).equals(
        const AppLockState.locked(isBiometricEnabled: true),
      );
    });

    test('lockApp: unlocked 状態から locked 状態へ復帰ロックされる', () async {
      final container = createContainer(
        isAuthenticated: true,
        hasPasscode: true,
        isBiometricEnabled: false,
      );
      await container.read(appLockServiceProvider.future);

      // 解除状態にするためスキップ実行
      container.read(appLockServiceProvider.notifier).skipBiometric();

      // パスコード解除やスキップ直後の復帰時は遅延なしで即座にロックされる
      container.read(appLockServiceProvider.notifier).lockApp();

      final state = container.read(appLockServiceProvider).value;
      check(state).equals(
        const AppLockState.locked(isBiometricEnabled: false),
      );
    });

    test('lockApp: 生体認証プロンプト閉じに伴う1回目の復帰イベントはスキップされる', () async {
      final container = createContainer(
        isAuthenticated: true,
        hasPasscode: true,
        isBiometricEnabled: true,
      );
      await container.read(appLockServiceProvider.future);

      when(
        () => mockRepository.authenticateWithBiometrics(
          localizedReason: 'Reason',
        ),
      ).thenAnswer((_) async => true);

      // 生体認証で解除
      await container
          .read(appLockServiceProvider.notifier)
          .unlockWithBiometrics(localizedReason: 'Reason');

      // 1回目の lockApp() はプロンプト閉じ起因の復帰イベントとしてスキップされる
      container.read(appLockServiceProvider.notifier).lockApp();

      final state = container.read(appLockServiceProvider).value;
      check(state).equals(
        const AppLockState.unlocked(isBiometricEnabled: true),
      );
    });

    test(
      'lockApp: 生体認証成功直後のプロンプト復帰(1回目)はスキップされ、 '
      'その後のバックグラウンド・復帰(2回目)では正常に再ロックされる',
      () async {
        final container = createContainer(
          isAuthenticated: true,
          hasPasscode: true,
          isBiometricEnabled: true,
        );
        await container.read(appLockServiceProvider.future);

        when(
          () => mockRepository.authenticateWithBiometrics(
            localizedReason: 'Reason',
          ),
        ).thenAnswer((_) async => true);

        // 生体認証成功で解除
        await container
            .read(appLockServiceProvider.notifier)
            .unlockWithBiometrics(localizedReason: 'Reason');

        // 1回目の lockApp() (生体認証プロンプト閉じ起因): スキップされる
        container.read(appLockServiceProvider.notifier).lockApp();

        final unlockedState = container.read(appLockServiceProvider).value;
        check(unlockedState).equals(
          const AppLockState.unlocked(isBiometricEnabled: true),
        );

        // 2回目の lockApp() (ユーザーによる手動バックグラウンド・復帰): 正常にロックされる
        container.read(appLockServiceProvider.notifier).lockApp();

        final lockedState = container.read(appLockServiceProvider).value;
        check(lockedState).equals(
          const AppLockState.locked(isBiometricEnabled: true),
        );
      },
    );

    test('clearAppLock: ロック情報をすべて削除し disabled 状態へ遷移する', () async {
      final container = createContainer(
        isAuthenticated: true,
        hasPasscode: true,
        isBiometricEnabled: true,
      );
      await container.read(appLockServiceProvider.future);

      when(() => mockRepository.clearAll()).thenAnswer((_) async {});

      await container.read(appLockServiceProvider.notifier).clearAppLock();

      final state = container.read(appLockServiceProvider).value;
      check(state).equals(const AppLockState.disabled());
      verify(() => mockRepository.clearAll()).called(1);
    });
  });
}

class _TestAuthStateNotifier extends AuthStateNotifier {
  _TestAuthStateNotifier({required bool isAuthenticated})
    : _isAuthenticated = isAuthenticated;
  final bool _isAuthenticated;

  @override
  Future<bool> build() async => _isAuthenticated;
}

class _TestFirebaseAuthStateNotifier extends FirebaseAuthStateNotifier {
  _TestFirebaseAuthStateNotifier(this._user);
  final User? _user;

  @override
  AsyncValue<User?> build() => AsyncValue.data(_user);
}
