part of '../app_router.dart';

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

/// 📊 グラフタブのブランチデータ
class ChartBranch extends StatefulShellBranchData {
  /// コンストラクタ
  const ChartBranch();
}

/// 📊 グラフタブのシェルブランチ定義
const chartShellBranch = TypedStatefulShellBranch<ChartBranch>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<ChartInputRoute>(
      path: '/chart-input',
      routes: [TypedGoRoute<ChartDisplayRoute>(path: 'display')],
    ),
  ],
);
