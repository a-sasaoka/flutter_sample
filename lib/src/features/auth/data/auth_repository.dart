import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/storage/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

/// 認証リポジトリ
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    api: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
}

/// 認証リポジトリの実装クラス
class AuthRepository {
  /// コンストラクタ
  AuthRepository({
    required this.api,
    required this.tokenStorage,
  });

  /// APIクライアント
  final ApiClient api;

  /// トークンストレージ
  final TokenStorage tokenStorage;

  /// ログインAPIを呼び出し、トークンを保存する
  Future<void> login(String email, String password) async {
    final response = await api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final access = response.data?['access_token'] as String?;
    final refresh = response.data?['refresh_token'] as String?;

    if (access == null || refresh == null) {
      throw const UnknownException(
        message: 'Invalid token response from server',
      );
    }

    await tokenStorage.saveTokens(
      accessToken: access,
      refreshToken: refresh,
    );
  }

  /// リフレッシュトークンAPIを呼び出し、アクセストークンを更新する
  Future<bool> refreshToken() async {
    final refresh = await tokenStorage.getRefreshToken();
    if (refresh == null) return false;

    final response = await api.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refresh},
    );

    final access = response.data?['access_token'] as String?;
    if (access == null) return false;

    await tokenStorage.saveTokens(
      accessToken: access,
      refreshToken: refresh,
    );
    return true;
  }
}
