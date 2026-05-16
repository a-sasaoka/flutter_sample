part of '../app_router.dart';

/// 🔐 ログイン画面ルート
@TypedGoRoute<LoginRoute>(
  path: '/login',
  routes: [
    TypedGoRoute<SignUpRoute>(path: 'signup'),
  ],
)
class LoginRoute extends GoRouteData with $LoginRoute {
  /// コンストラクタ
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return Consumer(
      builder: (context, ref, child) {
        // Firebase Authenticationの利用有無で遷移先画面を切り替える
        final useFirebase = ref.watch(envConfigProvider).useFirebaseAuth;
        if (useFirebase) {
          return const FirebaseLoginScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

/// 🧾 サインアップ画面ルート
class SignUpRoute extends GoRouteData with $SignUpRoute {
  /// コンストラクタ
  const SignUpRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FirebaseSignUpScreen();
  }
}

/// 📧 メールアドレス確認画面ルート
@TypedGoRoute<EmailVerificationRoute>(path: '/email-verification')
class EmailVerificationRoute extends GoRouteData with $EmailVerificationRoute {
  /// コンストラクタ
  const EmailVerificationRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FirebaseEmailVerificationScreen();
  }
}
