import 'package:flutter/foundation.dart';

/// 🔐 SecureStorage（暗号化ストレージ）の保存キー一覧
@immutable
abstract final class SecureStorageKeys {
  /// 認証用アクセストークン
  static const accessToken = 'access_token';

  /// 認証用リフレッシュトークン
  static const refreshToken = 'refresh_token';

  /// アプリロック用パスコード
  static const appLockPasscode = 'app_lock_passcode';

  /// アプリロック用生体認証有効フラグ
  static const appLockBiometricEnabled = 'app_lock_biometric_enabled';

  /// アプリロック用失敗回数
  static const appLockFailedAttempts = 'app_lock_failed_attempts';

  /// アプリロック用一時ロックアウト終了日時
  static const appLockLockoutUntil = 'app_lock_lockout_until';
}

/// 💾 SharedPreferences（標準ローカルストレージ）の保存キー一覧
@immutable
abstract final class SharedPrefKeys {
  /// テーマ設定 (system / light / dark)
  static const themeMode = 'theme_mode';

  /// ロケール言語設定 (ja / en)
  static const localeCode = 'locale_key';

  /// オンボーディング表示完了フラグ
  static const onboardingCompleted = 'onboarding_completed';
}
