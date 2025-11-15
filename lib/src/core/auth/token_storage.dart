import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_storage.g.dart';

/// トークンストレージクラス
@Riverpod(keepAlive: true)
class TokenStorage extends _$TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  @override
  void build() {}

  /// トークンを保存する
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  /// アクセストークンを取得する
  Future<String?> getAccessToken() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    return prefs.getString(_accessTokenKey);
  }

  /// リフレッシュトークンを取得する
  Future<String?> getRefreshToken() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    return prefs.getString(_refreshTokenKey);
  }

  /// トークンを削除する
  Future<void> clear() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}
