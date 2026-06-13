import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/app/router/base_auth_guard.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 認証状態に応じてリダイレクト先を判定するガード（認証トークン版）
String? authGuard(Ref ref, GoRouterState state) {
  // 現在のログイン状態を取得（コールバック内のため watch ではなく read を使用）
  final authState = ref.read(authStateProvider);

  // ローディング中はスプラッシュ表示
  // これが無いと認証済みの時に一瞬ログイン画面が表示される
  if (authState.isLoading) {
    return const SplashRoute().location;
  }

  // ユーザーがログイン済みかどうか
  final isLoggedIn = authState.value ?? false;

  // 共通の初期状態リダイレクト判定（スプラッシュ完了、オンボーディング進行状況など）
  final baseRedirect = checkBaseRedirect(
    ref: ref,
    state: state,
    isLoggedIn: isLoggedIn,
  );
  if (baseRedirect != null) {
    return baseRedirect;
  }

  return AuthGuardHelper(
    loginLocation: const LoginRoute().location,
    defaultLocation: const HomeRoute().location,
    guestOnlyPaths: {
      const LoginRoute().location,
    },
    alwaysPublicPaths: {
      const SplashRoute().location,
      const OnboardingRoute().location,
    },
  ).redirect(
    isLoggedIn: isLoggedIn,
    state: state,
  );
}
