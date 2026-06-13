import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/app/router/base_auth_guard.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 認証状態に応じてリダイレクト先を判定するガード（Firebase Authentication版）
String? firebaseAuthGuard(Ref ref, GoRouterState state) {
  // ログイン状態（ローディング状態含む）を取得
  final authStateAsync = ref.read(firebaseAuthStateProvider);

  // Firebaseのログイン確認が終わっていない（ローディング中）なら、スプラッシュ画面にとどまる
  if (authStateAsync.isLoading) {
    return const SplashRoute().location;
  }

  final authState = authStateAsync.value;

  // ユーザーがログイン済みかどうか
  final isLoggedIn = authState != null;

  // 共通の初期状態リダイレクト判定（スプラッシュ完了、オンボーディング進行状況など）
  final baseRedirect = checkBaseRedirect(
    ref: ref,
    state: state,
    isLoggedIn: isLoggedIn,
  );
  if (baseRedirect != null) {
    return baseRedirect;
  }

  // メール未認証の場合は、常にメール認証待ち画面へ誘導する
  final isEmailVerified = authState?.emailVerified ?? false;
  final emailVerificationPath = const EmailVerificationRoute().location;

  // クエリパラメータの影響を受けないようにパスのみを取得する
  final goingToEmailVerification = state.uri.path == emailVerificationPath;

  if (isLoggedIn && !isEmailVerified && !goingToEmailVerification) {
    return emailVerificationPath;
  }

  // メール認証が完了した状態でメール認証画面にアクセスした場合は、ホーム画面へリダイレクトする
  if (isLoggedIn && isEmailVerified && goingToEmailVerification) {
    return const HomeRoute().location;
  }

  return AuthGuardHelper(
    loginLocation: const LoginRoute().location,
    defaultLocation: const HomeRoute().location,
    guestOnlyPaths: {
      const LoginRoute().location,
      const SignUpRoute().location,
    },
    alwaysPublicPaths: {
      const SplashRoute().location,
      const OnboardingRoute().location,
      const ResetPasswordRoute().location,
    },
  ).redirect(
    isLoggedIn: isLoggedIn,
    state: state,
  );
}
