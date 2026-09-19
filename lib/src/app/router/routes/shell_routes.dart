part of '../app_router.dart';

/// 📱 アプリ全体を囲むボトムナビゲーション用のシェルルート
@TypedStatefulShellRoute<AppShellRouteData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    homeShellBranch,
    chatShellBranch,
    memosShellBranch,
    chartShellBranch,
    userShellBranch,
  ],
)
class AppShellRouteData extends StatefulShellRouteData {
  /// コンストラクタ
  const AppShellRouteData();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return MainShellScreen(navigationShell: navigationShell);
  }
}
