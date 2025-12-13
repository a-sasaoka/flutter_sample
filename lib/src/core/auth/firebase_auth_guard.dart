import 'package:flutter_sample/src/core/auth/base_auth_guard.dart';
import 'package:flutter_sample/src/core/auth/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 認証状態に応じてリダイレクト先を判定するガード
String? firebaseAuthGuard(Ref ref, GoRouterState state) {
  // 現在のログイン状態を取得（変更を監視）
  final authState = ref.watch(firebaseAuthStateProvider);

  // ユーザーがログイン済みかどうか
  final isLoggedIn = authState != null;

  // メール未認証の場合は、常にメール認証待ち画面へ誘導する
  final isEmailVerified = authState?.emailVerified ?? false;
  final emailVerificationPath = const EmailVerificationRoute().location;
  final goingToEmailVerification =
      state.uri.toString() == emailVerificationPath;
  if (isLoggedIn && !isEmailVerified && !goingToEmailVerification) {
    return emailVerificationPath;
  }

  return const AuthGuardHelper().redirect(
    isLoggedIn: isLoggedIn,
    state: state,
  );
}
