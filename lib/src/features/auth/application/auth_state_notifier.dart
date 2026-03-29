import 'package:flutter_sample/src/core/storage/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_notifier.g.dart';

/// ログイン状態を管理するStateNotifier
@Riverpod(keepAlive: true)
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStorageProvider).getAccessToken();
    return token != null; // トークンがあればログイン状態
  }

  /// ログイン状態にする
  Future<void> login(String accessToken, String refreshToken) async {
    // guard を使うことで例外時は自動で AsyncError 状態になる
    state = await AsyncValue.guard(() async {
      await ref
          .read(tokenStorageProvider)
          .saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
      return true;
    });
  }

  /// ログアウト状態にする
  Future<void> logout() async {
    state = await AsyncValue.guard(() async {
      await ref.read(tokenStorageProvider).clear();
      return false;
    });
  }
}
