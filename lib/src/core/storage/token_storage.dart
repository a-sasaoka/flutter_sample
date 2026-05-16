import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'token_storage.g.dart';

/// トークンストレージプロバイダー
@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TokenStorage(prefs: prefs);
}

/// トークンストレージクラス
class TokenStorage {
  /// コンストラクタ
  const TokenStorage({required SharedPreferencesAsync prefs}) : _prefs = prefs;

  final SharedPreferencesAsync _prefs;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  /// トークンを保存する
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait<void>([
      _prefs.setString(_accessTokenKey, accessToken),
      _prefs.setString(_refreshTokenKey, refreshToken),
    ]);
  }

  /// アクセストークンを取得する
  Future<String?> getAccessToken() async {
    return _prefs.getString(_accessTokenKey);
  }

  /// リフレッシュトークンを取得する
  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
  }

  /// トークンを削除する
  Future<void> clear() async {
    await Future.wait<void>([
      _prefs.remove(_accessTokenKey),
      _prefs.remove(_refreshTokenKey),
    ]);
  }
}
