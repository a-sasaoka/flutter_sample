import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/data/app_lock_repository.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_lock_service.g.dart';

/// 🔐 アプリロックのロジックと状態（sealed クラス）を管理する AsyncNotifier
@Riverpod(keepAlive: true)
class AppLockService extends _$AppLockService {
  /// パスコード連続失敗の最大許容回数
  static const int maxFailedAttempts = 3;

  /// 失敗上限に達した際の一時ロックアウト時間
  static const Duration lockOutDuration = Duration(seconds: 30);

  /// OS標準生体認証ダイアログの表示に伴うライフサイクル変化（resumed）による誤ロックを防ぐフラグ
  bool _isAuthenticating = false;

  /// 生体認証プロンプトが閉じられた直後の日時（OSイベントの遅延による誤ロック防止用）
  DateTime? _promptDismissedAt;

  /// パスコード連続失敗回数
  int _failedPasscodeAttempts = 0;

  /// 一時ロックアウト終了予定日時
  DateTime? _lockoutUntil;

  @override
  Future<AppLockState> build() async {
    final talker = ref.watch(loggerProvider);
    final useFirebase = ref.watch(envConfigProvider).useFirebaseAuth;

    // 認証状態の監視 (ログイン中かどうか判定)
    final isAuthenticated = useFirebase
        ? ref.watch(firebaseAuthStateProvider).value != null
        : ref.watch(authStateProvider).value == true;

    talker.debug('[AppLockService] build (isAuthenticated: $isAuthenticated)');

    // 未ログインの場合はロック無効状態（disabled）を返す
    if (!isAuthenticated) {
      return const AppLockState.disabled();
    }

    // 非同期でパスコード・生体認証設定を安全に読み込み
    final repository = ref.watch(appLockRepositoryProvider);
    final hasPasscode = await repository.hasPasscode();
    final isBiometricEnabled = await repository.isBiometricEnabled();

    talker.debug(
      '[AppLockService] Initializing '
      '(hasPasscode: $hasPasscode, isBiometricEnabled: $isBiometricEnabled)',
    );

    if (!hasPasscode) {
      // パスコード未設定の場合は初期設定誘導状態へ
      return const AppLockState.setupRequired();
    } else {
      // パスコード設定済みの場合はアプリ起動時にロック状態へ
      return AppLockState.locked(isBiometricEnabled: isBiometricEnabled);
    }
  }

  /// パスコードを保存し、端末が生体認証可能かどうかを返す
  Future<bool> setupPasscode(String passcode) async {
    final repository = ref.read(appLockRepositoryProvider);
    await repository.savePasscode(passcode);
    ref.read(loggerProvider).info('[AppLockService] Passcode saved');

    return repository.canCheckBiometrics();
  }

  /// 生体認証を使わずに初期設定を完了する（スキップ時）
  void skipBiometric() {
    ref.read(loggerProvider).info('[AppLockService] Biometric skipped');
    state = const AsyncValue.data(
      AppLockState.unlocked(isBiometricEnabled: false),
    );
  }

  /// 生体認証の有効化（動作テストを行い、成功した場合のみON、キャンセル時も設定完了として進む）
  Future<bool> enableBiometric({required String localizedReason}) async {
    _isAuthenticating = true;
    final repository = ref.read(appLockRepositoryProvider);

    try {
      final authenticated = await repository.authenticateWithBiometrics(
        localizedReason: localizedReason,
      );

      _promptDismissedAt = ref.read(clockProvider)();

      if (authenticated) {
        // 成功した場合: 生体認証を有効にして設定完了し、早期リターン
        await repository.setBiometricEnabled(enabled: true);

        // OSのFace IDダイアログが完全に消え去るまで余裕を持って1000ms待機
        await Future<void>.delayed(const Duration(milliseconds: 1000));

        state = const AsyncValue.data(
          AppLockState.unlocked(isBiometricEnabled: true),
        );
        ref.read(loggerProvider).info('[AppLockService] Biometric enabled');
        return true;
      }

      // キャンセル・失敗した場合: パスコード設定は完了しているため、生体認証OFFで進む
      await repository.setBiometricEnabled(enabled: false);
      state = const AsyncValue.data(
        AppLockState.unlocked(isBiometricEnabled: false),
      );
      ref
          .read(loggerProvider)
          .info('[AppLockService] Biometric cancelled/disabled');

      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  /// パスコード入力によるロック解除試行
  Future<bool> unlockWithPasscode(String passcode) async {
    final now = ref.read(clockProvider)();
    if (_lockoutUntil != null) {
      if (now.isBefore(_lockoutUntil!)) {
        ref
            .read(loggerProvider)
            .warning('[AppLockService] Passcode attempt rejected (locked out)');
        return false;
      }
      _lockoutUntil = null;
    }

    final repository = ref.read(appLockRepositoryProvider);
    final isValid = await repository.verifyPasscode(passcode);

    if (!isValid) {
      _failedPasscodeAttempts++;
      if (_failedPasscodeAttempts >= maxFailedAttempts) {
        _lockoutUntil = now.add(lockOutDuration);
        _failedPasscodeAttempts = 0;
        ref
            .read(loggerProvider)
            .warning(
              '[AppLockService] Passcode failed. Lockout threshold reached '
              '($maxFailedAttempts attempts). '
              'Locked out for ${lockOutDuration.inSeconds}s',
            );
      } else {
        ref
            .read(loggerProvider)
            .warning(
              '[AppLockService] Passcode failed (attempt $_failedPasscodeAttempts/$maxFailedAttempts)',
            );
      }
      return false;
    }

    _failedPasscodeAttempts = 0;
    _lockoutUntil = null;

    final isBiometricEnabled = await repository.isBiometricEnabled();
    state = AsyncValue.data(
      AppLockState.unlocked(isBiometricEnabled: isBiometricEnabled),
    );
    ref.read(loggerProvider).info('[AppLockService] Unlocked with passcode');

    return true;
  }

  /// 生体認証によるロック解除試行
  Future<bool> unlockWithBiometrics({required String localizedReason}) async {
    final currentState = state.value;
    if (currentState is! AppLockStateLocked ||
        !currentState.isBiometricEnabled) {
      return false;
    }

    _isAuthenticating = true;
    final repository = ref.read(appLockRepositoryProvider);

    try {
      final authenticated = await repository.authenticateWithBiometrics(
        localizedReason: localizedReason,
      );

      if (!authenticated) {
        ref.read(loggerProvider).warning('[AppLockService] Biometric failed');
        return false;
      }

      _promptDismissedAt = ref.read(clockProvider)();

      // OSのFace IDダイアログが完全に消え去るまで余裕を持って1000ms待機
      await Future<void>.delayed(const Duration(milliseconds: 1000));

      state = const AsyncValue.data(
        AppLockState.unlocked(isBiometricEnabled: true),
      );
      ref
          .read(loggerProvider)
          .info('[AppLockService] Unlocked with biometrics');

      return true;
    } finally {
      _isAuthenticating = false;
    }
  }

  /// アプリをロック状態にする（バックグラウンド復帰時など）
  void lockApp() {
    if (_isAuthenticating) {
      return; // 生体認証実行中は誤ロック防止のためスキップ
    }

    // OSの生体認証プロンプトが閉じられた直後（2秒以内）の復帰イベントのみを消費・スキップ
    if (_promptDismissedAt != null) {
      final elapsed = ref.read(clockProvider)().difference(_promptDismissedAt!);
      _promptDismissedAt = null; // プロンプト起因のイベントを消費
      if (elapsed < const Duration(seconds: 2)) {
        return;
      }
    }

    final currentState = state.value;
    if (currentState is AppLockStateUnlocked) {
      ref.read(loggerProvider).info('[AppLockService] App locked');
      state = AsyncValue.data(
        AppLockState.locked(
          isBiometricEnabled: currentState.isBiometricEnabled,
        ),
      );
    }
  }

  /// アプリロック状態のクリア (ログアウト時など)
  Future<void> clearAppLock() async {
    final repository = ref.read(appLockRepositoryProvider);
    await repository.clearAll();
    _promptDismissedAt = null;
    _failedPasscodeAttempts = 0;
    _lockoutUntil = null;
    state = const AsyncValue.data(AppLockState.disabled());
  }
}
