import 'package:flutter_sample/src/core/auth/token_storage.dart';
import 'package:flutter_sample/src/data/datasource/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

/// 認証リポジトリ
@Riverpod(keepAlive: true)
class AuthRepository extends _$AuthRepository {
  @override
  void build() {}

  /// ログインAPIを呼び出し、トークンを保存する
  Future<void> login(String email, String password) async {
    final api = ref.read(apiClientProvider);
    final response = await api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final access = response.data?['access_token'] as String;
    final refresh = response.data?['refresh_token'] as String;

    await ref
        .read(tokenStorageProvider.notifier)
        .saveTokens(
          accessToken: access,
          refreshToken: refresh,
        );
  }

  /// リフレッシュトークンAPIを呼び出し、アクセストークンを更新する
  Future<bool> refreshToken() async {
    final refresh = await ref
        .read(tokenStorageProvider.notifier)
        .getRefreshToken();
    if (refresh == null) return false;

    final api = ref.read(apiClientProvider);
    final response = await api.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refresh},
    );

    final access = response.data?['access_token'];
    if (access == null) return false;

    await ref
        .read(tokenStorageProvider.notifier)
        .saveTokens(
          accessToken: access as String,
          refreshToken: refresh,
        );
    return true;
  }
}
