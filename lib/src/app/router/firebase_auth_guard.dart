import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/app/router/base_auth_guard.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
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

  // 現在のログイン状態を取得（コールバック内のため watch ではなく read を使用）
  final authState = ref.read(firebaseAuthStateProvider);

  // ユーザーがログイン済みかどうか
  final isLoggedIn = authState != null;

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
      const ResetPasswordRoute().location,
    },
  ).redirect(
    isLoggedIn: isLoggedIn,
    state: state,
  );
}
