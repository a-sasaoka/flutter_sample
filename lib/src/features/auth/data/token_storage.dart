import 'package:flutter_sample/src/app/constants/storage_keys.dart';
import 'package:flutter_sample/src/core/storage/secure_storage_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_storage.g.dart';

/// トークンストレージプロバイダー
@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return TokenStorage(secureStorage: secureStorage);
}

/// トークンストレージクラス
class TokenStorage {
  /// コンストラクタ
  const TokenStorage({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;

  /// トークンを保存する
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(
      key: SecureStorageKeys.accessToken,
      value: accessToken,
    );
    await _secureStorage.write(
      key: SecureStorageKeys.refreshToken,
      value: refreshToken,
    );
  }

  /// アクセストークンを取得する
  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: SecureStorageKeys.accessToken);
  }

  /// リフレッシュトークンを取得する
  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: SecureStorageKeys.refreshToken);
  }

  /// トークンを削除する
  Future<void> clear() async {
    await _secureStorage.delete(key: SecureStorageKeys.accessToken);
    await _secureStorage.delete(key: SecureStorageKeys.refreshToken);
  }
}
