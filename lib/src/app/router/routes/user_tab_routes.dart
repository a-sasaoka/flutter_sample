part of '../app_router.dart';

/// 👥 ユーザー一覧画面ルート
class UserListRoute extends GoRouteData with $UserListRoute {
  /// コンストラクタ
  const UserListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const UserListScreen();
  }
}

/// 👥 ユーザー一覧タブのブランチデータ
class UserBranch extends StatefulShellBranchData {
  /// コンストラクタ
  const UserBranch();
}

/// 👥 ユーザー一覧タブのシェルブランチ定義
const userShellBranch = TypedStatefulShellBranch<UserBranch>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<UserListRoute>(path: '/users'),
  ],
);
