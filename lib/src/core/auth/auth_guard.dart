import 'package:flutter_sample/src/core/auth/auth_state_notifier.dart';
import 'package:flutter_sample/src/core/auth/base_auth_guard.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 認証状態に応じてリダイレクト先を判定するガード
String? authGuard(Ref ref, GoRouterState state) {
  // 現在のログイン状態を取得（変更を監視）
  final authState = ref.watch(authStateProvider);

  // ローディング中はスプラッシュ表示
  // これが無いと認証済みの時に一瞬ログイン画面が表示される
  if (authState.isLoading) {
    return const SplashRoute().location;
  }

  // ユーザーがログイン済みかどうか
  final isLoggedIn = authState.value ?? false;

  return const AuthGuardHelper().redirect(
    isLoggedIn: isLoggedIn,
    state: state,
  );
}
