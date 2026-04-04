import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/app/router/base_auth_guard.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 認証状態に応じてリダイレクト先を判定するガード
String? firebaseAuthGuard(Ref ref, GoRouterState state) {
  // 現在のログイン状態を取得（コールバック内のため watch ではなく read を使用）
  final authState = ref.read(firebaseAuthStateProvider);

  // ユーザーがログイン済みかどうか
  final isLoggedIn = authState != null;

  // メール未認証の場合は、常にメール認証待ち画面へ誘導する
  final isEmailVerified = authState?.emailVerified ?? false;
  final emailVerificationPath = const EmailVerificationRoute().location;

  // クエリパラメータの影響を受けないようにパスのみを取得する
  final goingToEmailVerification = state.uri.path == emailVerificationPath;

  if (isLoggedIn && !isEmailVerified && !goingToEmailVerification) {
    return emailVerificationPath;
  }

  return const AuthGuardHelper().redirect(
    isLoggedIn: isLoggedIn,
    state: state,
  );
}
