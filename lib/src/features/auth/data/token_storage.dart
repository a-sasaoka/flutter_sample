import 'package:flutter_sample/src/app/constants/storage_keys.dart';
import 'package:flutter_sample/src/core/storage/secure_storage_provider.dart';
import 'package:flutter_sample/src/core/utils/jwt_utils.dart';
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

    // JWTからユーザーIDを抽出して暗号化保存
    final userId = JwtUtils.getUserId(accessToken);
    if (userId != null) {
      await _secureStorage.write(
        key: SecureStorageKeys.customUserId,
        value: userId,
      );
    }
  }

  /// アクセストークンを取得する
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: SecureStorageKeys.accessToken);
  }

  /// リフレッシュトークンを取得する
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: SecureStorageKeys.refreshToken);
  }

  /// ログイン中ユーザーIDを取得する（未保存時はアクセストークンからの復元も試行）
  Future<String?> getUserId() async {
    final storedUserId = await _secureStorage.read(
      key: SecureStorageKeys.customUserId,
    );
    if (storedUserId != null) {
      return storedUserId;
    }

    // 後方互換性：トークンから復元して保存
    final token = await getAccessToken();
    if (token != null) {
      final userId = JwtUtils.getUserId(token);
      if (userId != null) {
        await _secureStorage.write(
          key: SecureStorageKeys.customUserId,
          value: userId,
        );
        return userId;
      }
    }
    return null;
  }

  /// トークンおよびユーザーIDを削除する
  Future<void> clear() async {
    await _secureStorage.delete(key: SecureStorageKeys.accessToken);
    await _secureStorage.delete(key: SecureStorageKeys.refreshToken);
    await _secureStorage.delete(key: SecureStorageKeys.customUserId);
  }
}
