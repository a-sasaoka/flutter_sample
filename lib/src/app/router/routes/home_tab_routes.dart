part of '../app_router.dart';

/// 🏠 ホーム画面ルート
class HomeRoute extends GoRouteData with $HomeRoute {
  /// コンストラクタ
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomeScreen();
  }
}

/// ⚙️ 設定画面ルート
class SettingsRoute extends GoRouteData with $SettingsRoute {
  /// コンストラクタ
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsScreen();
  }
}

/// 🔑 パスワードリセット画面ルート
class ResetPasswordRoute extends GoRouteData with $ResetPasswordRoute {
  /// コンストラクタ
  const ResetPasswordRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FirebaseResetPasswordScreen();
  }
}

/// 👤 プロフィール編集画面ルート
class ProfileEditRoute extends GoRouteData with $ProfileEditRoute {
  /// コンストラクタ
  const ProfileEditRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProfileEditScreen();
  }
}
