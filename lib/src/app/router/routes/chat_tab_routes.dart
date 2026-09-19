part of '../app_router.dart';

/// 🤖 AIチャット画面ルート
class ChatRoute extends GoRouteData with $ChatRoute {
  /// コンストラクタ
  const ChatRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ChatScreen();
  }
}

/// 🤖 チャットタブのブランチデータ
class ChatBranch extends StatefulShellBranchData {
  /// コンストラクタ
  const ChatBranch();
}

/// 🤖 チャットタブのシェルブランチ定義
const chatShellBranch = TypedStatefulShellBranch<ChatBranch>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<ChatRoute>(path: '/chat'),
  ],
);
