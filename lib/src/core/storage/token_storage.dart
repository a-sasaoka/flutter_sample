import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_storage.g.dart';

/// トークンストレージプロバイダー
@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) {
  return TokenStorage._(ref);
}

/// トークンストレージクラス
class TokenStorage {
  TokenStorage._(this._ref);
  final Ref _ref;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  /// トークンを保存する
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await Future.wait([
      prefs.setString(_accessTokenKey, accessToken),
      prefs.setString(_refreshTokenKey, refreshToken),
    ]);
  }

  /// アクセストークンを取得する
  Future<String?> getAccessToken() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    return prefs.getString(_accessTokenKey);
  }

  /// リフレッシュトークンを取得する
  Future<String?> getRefreshToken() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    return prefs.getString(_refreshTokenKey);
  }

  /// トークンを削除する
  Future<void> clear() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await Future.wait([
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
    ]);
  }
}
