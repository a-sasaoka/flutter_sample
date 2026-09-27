part of '../app_router.dart';

/// 📝 メモ一覧画面ルート
class MemosRoute extends GoRouteData with $MemosRoute {
  /// コンストラクタ
  const MemosRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    String? action;
    try {
      action = state.uri.queryParameters['action'];
    } on Object catch (_) {
      action = null;
    }
    return MemoScreen(action: action);
  }
}

/// 📝 メモタブのブランチデータ
class MemosBranch extends StatefulShellBranchData {
  /// コンストラクタ
  const MemosBranch();
}

/// 📝 メモタブのシェルブランチ定義
const memosShellBranch = TypedStatefulShellBranch<MemosBranch>(
  routes: <TypedRoute<RouteData>>[TypedGoRoute<MemosRoute>(path: '/memos')],
);
