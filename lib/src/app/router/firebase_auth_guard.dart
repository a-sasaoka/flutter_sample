import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/app/router/base_auth_guard.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_state_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 認証状態に応じてリダイレクト先を判定するガード（Firebase Authentication版）
String? firebaseAuthGuard(Ref ref, GoRouterState state) {
  // スプラッシュ画面の表示が完了していない場合は、強制的にスプラッシュ画面にとどまる
  final isSplashFinished = ref.read(splashStateProvider);
  if (!isSplashFinished) {
    return const SplashRoute().location;
  }

  // オンボーディングの状態を取得
  final onboardingState = ref.read(onboardingProvider);
  final onboardingLocation = const OnboardingRoute().location;

  // エラー発生時はオンボーディング未完了として処理する
  if (onboardingState.hasError) {
    if (state.uri.path != onboardingLocation) {
      return onboardingLocation;
    }
    return null;
  }

  // オンボーディングデータの読み込み中はスプラッシュ画面へ案内する
  // ただし、すでにオンボーディング画面にいる場合はリダイレクトしない
  if (onboardingState.isLoading) {
    if (state.uri.path != onboardingLocation) {
      return const SplashRoute().location;
    }
    return null;
  }

  final isOnboardingCompleted = onboardingState.value ?? false;

  // ログイン状態（ローディング状態含む）を取得
  final authStateAsync = ref.read(firebaseAuthStateProvider);

  // Firebaseのログイン確認が終わっていない（ローディング中）なら、スプラッシュ画面にとどまる
  if (authStateAsync.isLoading) {
    return const SplashRoute().location;
  }

  final authState = authStateAsync.value;

  // ユーザーがログイン済みかどうか
  final isLoggedIn = authState != null;

  // オンボーディングが未完了の場合はオンボーディング画面へリダイレクト（現在地がオンボーディング画面以外の場合）
  if (!isOnboardingCompleted && state.uri.path != onboardingLocation) {
    return onboardingLocation;
  }

  // すでにオンボーディング完了済みでオンボーディング画面にいる場合はリダイレクト
  if (isOnboardingCompleted && state.uri.path == onboardingLocation) {
    return isLoggedIn
        ? const HomeRoute().location
        : const LoginRoute().location;
  }

  // スプラッシュ表示が完了しており、かつ現在スプラッシュ画面にいる場合は、
  // ログイン状態に応じた適切な画面（ホームまたはログイン）へリダイレクトする
  if (state.uri.path == const SplashRoute().location) {
    return isLoggedIn
        ? const HomeRoute().location
        : const LoginRoute().location;
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
