part of '../app_router.dart';

/// 🏠 ホーム画面ルート
@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [
    TypedGoRoute<SettingsRoute>(path: 'settings'),
    TypedGoRoute<UserListRoute>(path: 'users'),
    TypedGoRoute<ResetPasswordRoute>(path: 'reset-password'),
    TypedGoRoute<ChatRoute>(path: 'chat'),
    TypedGoRoute<MemosRoute>(path: 'memos'),
    TypedGoRoute<ChartInputRoute>(
      path: 'chart-input',
      routes: [
        TypedGoRoute<ChartDisplayRoute>(path: 'display'),
      ],
    ),
  ],
)
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

/// 📊 グラフ入力画面ルート
class ChartInputRoute extends GoRouteData with $ChartInputRoute {
  /// コンストラクタ
  const ChartInputRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ChartInputScreen();
  }
}

/// 📈 グラフ表示画面ルート
class ChartDisplayRoute extends GoRouteData with $ChartDisplayRoute {
  /// コンストラクタ
  const ChartDisplayRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ChartDisplayScreen();
  }
}

/// 👥 ユーザー一覧画面ルート
class UserListRoute extends GoRouteData with $UserListRoute {
  /// コンストラクタ
  const UserListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const UserListScreen();
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

/// 🤖 AIチャット画面ルート
class ChatRoute extends GoRouteData with $ChatRoute {
  /// コンストラクタ
  const ChatRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ChatScreen();
  }
}

/// 📝 メモ一覧画面ルート
class MemosRoute extends GoRouteData with $MemosRoute {
  /// コンストラクタ
  const MemosRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MemoScreen();
  }
}
