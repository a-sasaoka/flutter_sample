// lib/src/core/auth/token_storage.dart
// トークンをSharedPreferencesに保存・取得

import 'package:flutter_sample/src/core/config/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// トークンストレージクラス
class TokenStorage {
  /// コンストラクタ
  TokenStorage(this.ref);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  /// RiverpodのRef
  final Ref ref;

  /// トークンを保存する
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  /// アクセストークンを取得する
  Future<String?> getAccessToken() async {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getString(_accessTokenKey);
  }

  /// リフレッシュトークンを取得する
  Future<String?> getRefreshToken() async {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getString(_refreshTokenKey);
  }

  /// トークンを削除する
  Future<void> clear() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}
