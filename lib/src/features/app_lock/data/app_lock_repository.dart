import 'package:flutter_sample/src/core/storage/secure_storage_provider.dart';
import 'package:flutter_sample/src/features/app_lock/data/local_authentication_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_lock_repository.g.dart';

/// 🔐 パスコードの安全な保存と生体認証を扱うリポジトリ
class AppLockRepository {
  /// コンストラクタ
  const AppLockRepository({
    required FlutterSecureStorage secureStorage,
    required LocalAuthentication localAuth,
  }) : _secureStorage = secureStorage,
       _localAuth = localAuth;

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  static const _passcodeKey = 'app_lock_passcode';
  static const _biometricEnabledKey = 'app_lock_biometric_enabled';
  static const _failedAttemptsKey = 'app_lock_failed_attempts';
  static const _lockoutUntilKey = 'app_lock_lockout_until';

  /// パスコードが設定されているか取得
  Future<bool> hasPasscode() async {
    final passcode = await _secureStorage.read(key: _passcodeKey);
    return passcode != null && passcode.isNotEmpty;
  }

  /// パスコードを保存
  Future<void> savePasscode(String passcode) async {
    await _secureStorage.write(key: _passcodeKey, value: passcode);
  }

  /// 入力されたパスコードが正しいか検証
  Future<bool> verifyPasscode(String passcode) async {
    final savedPasscode = await _secureStorage.read(key: _passcodeKey);
    return savedPasscode == passcode;
  }

  /// 生体認証が有効になっているか取得
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// 生体認証の有効/無効を設定
  Future<void> setBiometricEnabled({required bool enabled}) async {
    await _secureStorage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  /// パスコード連続失敗回数を取得
  Future<int> getFailedAttempts() async {
    final value = await _secureStorage.read(key: _failedAttemptsKey);
    return value != null ? int.tryParse(value) ?? 0 : 0;
  }

  /// パスコード連続失敗回数を保存
  Future<void> saveFailedAttempts(int attempts) async {
    await _secureStorage.write(
      key: _failedAttemptsKey,
      value: attempts.toString(),
    );
  }

  /// ロックアウト終了日時を取得
  Future<DateTime?> getLockoutUntil() async {
    final value = await _secureStorage.read(key: _lockoutUntilKey);
    return value != null ? DateTime.tryParse(value) : null;
  }

  /// ロックアウト終了日時を保存（null の場合は削除）
  Future<void> saveLockoutUntil(DateTime? lockoutUntil) async {
    if (lockoutUntil == null) {
      await _secureStorage.delete(key: _lockoutUntilKey);
    } else {
      await _secureStorage.write(
        key: _lockoutUntilKey,
        value: lockoutUntil.toIso8601String(),
      );
    }
  }

  /// 失敗カウントとロックアウト日時をリセット
  Future<void> resetLockout() async {
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _lockoutUntilKey);
  }

  /// 端末が生体認証に対応し、かつ実際に登録・有効化されているか判定
  Future<bool> canCheckBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      return isSupported && availableBiometrics.isNotEmpty;
    } on Exception catch (_) {
      return false;
    }
  }

  /// OS標準の生体認証ダイアログを起動して認証実行
  Future<bool> authenticateWithBiometrics({
    required String localizedReason,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on Exception catch (_) {
      return false;
    }
  }

  /// すべてのロック関連設定をクリア (ログアウト時など)
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _passcodeKey);
    await _secureStorage.delete(key: _biometricEnabledKey);
    await resetLockout();
  }
}

/// AppLockRepository を提供するプロバイダー
@Riverpod(keepAlive: true)
AppLockRepository appLockRepository(Ref ref) {
  return AppLockRepository(
    secureStorage: ref.watch(secureStorageProvider),
    localAuth: ref.watch(localAuthenticationProvider),
  );
}
