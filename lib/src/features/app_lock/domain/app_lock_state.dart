import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_lock_state.freezed.dart';

/// 🔐 アプリロックの状態を表す sealed クラス
@freezed
sealed class AppLockState with _$AppLockState {
  /// 未ログイン等、アプリロックが無効な状態
  const factory AppLockState.disabled() = AppLockStateDisabled;

  /// パスコード未設定のため、初期設定画面への誘導が必要な状態
  const factory AppLockState.setupRequired() = AppLockStateSetupRequired;

  /// ロック中（最前面シールド＋生体認証/PIN入力待機中）
  const factory AppLockState.locked({
    required bool isBiometricEnabled,
  }) = AppLockStateLocked;

  /// ロック解除済み（通常のアプリ利用可能状態）
  const factory AppLockState.unlocked({
    required bool isBiometricEnabled,
  }) = AppLockStateUnlocked;
}
