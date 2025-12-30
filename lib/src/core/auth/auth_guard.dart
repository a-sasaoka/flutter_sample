import 'package:flutter_sample/src/core/auth/auth_state_notifier.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 認証ガード
String? authGuard(Ref ref, GoRouterState state) {
  // ログイン状態を取得
  final authState = ref.watch(authStateProvider);

  // ローディング中はスプラッシュ表示
  // これが無いと認証済みの時に一瞬ログイン画面が表示される
  if (authState.isLoading) {
    return const SplashRoute().location;
  }

  final isLoggedIn = authState.value ?? false;

  // 未ログイン時に /login へ
  if (!isLoggedIn && state.uri.toString() != '/login') {
    final uri = state.uri.toString();
    return LoginRoute(redirectTo: uri).location;
  }

  // ログイン済みかつ /login にいる場合 → ホームへ
  if (isLoggedIn && state.uri.toString() == '/login') {
    return const HomeRoute().location;
  }

  return null; // 変更なし
}
