import 'package:flutter_sample/src/core/auth/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_notifier.g.dart';

/// ログイン状態を管理するStateNotifier
@Riverpod(keepAlive: true)
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  Future<bool> build() async {
    final token = await ref
        .read(tokenStorageProvider.notifier)
        .getAccessToken();
    return token != null; // トークンがあればログイン状態
  }

  /// ログイン状態にする
  Future<void> login(String accessToken, String refreshToken) async {
    await ref
        .read(tokenStorageProvider.notifier)
        .saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
    state = const AsyncData(true);
  }

  /// ログアウト状態にする
  Future<void> logout() async {
    await ref.read(tokenStorageProvider.notifier).clear();
    state = const AsyncData(false);
  }
}
