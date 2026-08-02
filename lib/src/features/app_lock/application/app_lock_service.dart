import 'dart:math' as math;

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

  /// 失敗上限に達した際の基本ロックアウト時間
  static const Duration baseLockOutDuration = Duration(seconds: 30);

  /// OSの生体認証プロンプトが完全に消去されるまでの待機時間
  static const Duration biometricPromptDelay = Duration(milliseconds: 1000);

  /// OS標準生体認証ダイアログの表示に伴うライフサイクル変化（resumed）による誤ロックを防ぐフラグ
  bool _isAuthenticating = false;

  /// OSの生体認証プロンプト消去起因の1回限りの復帰イベントを消費してスキップするフラグ
  bool _shouldSkipNextLock = false;

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

      _shouldSkipNextLock = true;

      if (authenticated) {
        // 成功した場合: 生体認証を有効にして設定完了し、早期リターン
        await repository.setBiometricEnabled(enabled: true);

        // OSのFace IDダイアログが完全に消え去るまで余裕を持って1000ms待機
        await Future<void>.delayed(biometricPromptDelay);

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
  Future<UnlockResult> unlockWithPasscode(String passcode) async {
    final repository = ref.read(appLockRepositoryProvider);
    final now = ref.read(clockProvider)();

    final lockoutUntil = await repository.getLockoutUntil();
    if (lockoutUntil != null) {
      if (now.isBefore(lockoutUntil)) {
        ref
            .read(loggerProvider)
            .warning(
              '[AppLockService] Passcode attempt rejected '
              '(locked out until $lockoutUntil)',
            );
        return UnlockResultLockedOut(lockoutUntil);
      }
      await repository.saveLockoutUntil(null);
    }

    final isValid = await repository.verifyPasscode(passcode);
    if (!isValid) {
      final currentAttempts = await repository.getFailedAttempts();
      final newAttempts = currentAttempts + 1;
      await repository.saveFailedAttempts(newAttempts);

      if (newAttempts >= maxFailedAttempts) {
        final exponent = math.min(newAttempts - maxFailedAttempts, 6);
        final multiplier = math.pow(2, exponent).toInt();
        final delaySeconds = baseLockOutDuration.inSeconds * multiplier;
        final nextLockoutUntil = now.add(Duration(seconds: delaySeconds));

        await repository.saveLockoutUntil(nextLockoutUntil);
        ref
            .read(loggerProvider)
            .warning(
              '[AppLockService] Passcode failed. Lockout threshold reached '
              '($newAttempts attempts). '
              'Locked out for ${delaySeconds}s',
            );
        return UnlockResultLockedOut(nextLockoutUntil);
      } else {
        ref
            .read(loggerProvider)
            .warning(
              '[AppLockService] Passcode failed (attempt $newAttempts/$maxFailedAttempts)',
            );
        return const UnlockResultInvalidPasscode();
      }
    }

    await repository.resetLockout();

    final isBiometricEnabled = await repository.isBiometricEnabled();
    state = AsyncValue.data(
      AppLockState.unlocked(isBiometricEnabled: isBiometricEnabled),
    );
    ref.read(loggerProvider).info('[AppLockService] Unlocked with passcode');

    return const UnlockResultSuccess();
  }

  /// 生体認証によるロック解除試行
  Future<bool> unlockWithBiometrics({required String localizedReason}) async {
    if (state.value case AppLockStateLocked(isBiometricEnabled: true)) {
      // ロック状態かつ生体認証が有効な場合のみ処理を継続
    } else {
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

      _shouldSkipNextLock = true;

      // OSのFace IDダイアログが完全に消え去るまで余裕を持って1000ms待機
      await Future<void>.delayed(biometricPromptDelay);

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

    // OSの生体認証プロンプトが閉じられたことによる1回限りの復帰イベントを消費・スキップ
    if (_shouldSkipNextLock) {
      _shouldSkipNextLock = false;
      return;
    }

    if (state.value case AppLockStateUnlocked(:final isBiometricEnabled)) {
      ref.read(loggerProvider).info('[AppLockService] App locked');
      state = AsyncValue.data(
        AppLockState.locked(
          isBiometricEnabled: isBiometricEnabled,
        ),
      );
    }
  }

  /// アプリロック状態のクリア (ログアウト時など)
  Future<void> clearAppLock() async {
    final repository = ref.read(appLockRepositoryProvider);
    await repository.clearAll();
    _shouldSkipNextLock = false;
    state = const AsyncValue.data(AppLockState.disabled());
  }
}

/// 🔐 パスコード認証の結果を表す sealed クラス
sealed class UnlockResult {
  const UnlockResult();
}

/// 認証成功
final class UnlockResultSuccess extends UnlockResult {
  /// コンストラクタ
  const UnlockResultSuccess();
}

/// パスコード不一致
final class UnlockResultInvalidPasscode extends UnlockResult {
  /// コンストラクタ
  const UnlockResultInvalidPasscode();
}

/// 一時ロックアウト状態
final class UnlockResultLockedOut extends UnlockResult {
  /// コンストラクタ
  const UnlockResultLockedOut(this.lockedOutUntil);

  /// ロックアウト終了予定日時
  final DateTime lockedOutUntil;
}
