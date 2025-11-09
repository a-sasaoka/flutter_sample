// lib/src/core/auth/auth_state_notifier.dart

import 'package:flutter_sample/src/core/auth/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_notifier.g.dart';

/// ログイン状態を管理するStateNotifier
@Riverpod(keepAlive: true)
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  Future<bool> build() async {
    final token = await TokenStorage(ref).getAccessToken();
    return token != null; // トークンがあればログイン状態
  }

  /// ログイン処理
  Future<void> login(String accessToken, String refreshToken) async {
    await TokenStorage(ref).saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    state = const AsyncData(true);
  }

  /// ログアウト処理
  Future<void> logout() async {
    await TokenStorage(ref).clear();
    state = const AsyncData(false);
  }
}
