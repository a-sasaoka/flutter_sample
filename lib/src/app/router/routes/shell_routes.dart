part of '../app_router.dart';

/// 📱 アプリ全体を囲むボトムナビゲーション用のシェルルート
@TypedStatefulShellRoute<AppShellRouteData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    // 1. ホームタブのブランチ
    TypedStatefulShellBranch<HomeBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<HomeRoute>(
          path: '/',
          routes: [
            TypedGoRoute<SettingsRoute>(path: 'settings'),
            TypedGoRoute<ResetPasswordRoute>(path: 'reset-password'),
          ],
        ),
      ],
    ),
    // 2. チャットタブのブランチ
    TypedStatefulShellBranch<ChatBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<ChatRoute>(path: '/chat'),
      ],
    ),
    // 3. メモタブのブランチ
    TypedStatefulShellBranch<MemosBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<MemosRoute>(path: '/memos'),
      ],
    ),
    // 4. グラフタブのブランチ
    TypedStatefulShellBranch<ChartBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<ChartInputRoute>(
          path: '/chart-input',
          routes: [
            TypedGoRoute<ChartDisplayRoute>(path: 'display'),
          ],
        ),
      ],
    ),
    // 5. ユーザー一覧タブのブランチ
    TypedStatefulShellBranch<UserBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<UserListRoute>(path: '/users'),
      ],
    ),
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

/// 🏠 ホームタブのブランチデータ
class HomeBranch extends StatefulShellBranchData {
  /// コンストラクタ
  const HomeBranch(); // coverage:ignore-line
}

/// 🤖 チャットタブのブランチデータ
class ChatBranch extends StatefulShellBranchData {
  /// コンストラクタ
  const ChatBranch(); // coverage:ignore-line
}

/// 📝 メモタブのブランチデータ
class MemosBranch extends StatefulShellBranchData {
  /// コンストラクタ
  const MemosBranch(); // coverage:ignore-line
}

/// 📊 グラフタブのブランチデータ
class ChartBranch extends StatefulShellBranchData {
  /// コンストラクタ
  const ChartBranch(); // coverage:ignore-line
}

/// 👥 ユーザー一覧タブのブランチデータ
class UserBranch extends StatefulShellBranchData {
  /// コンストラクタ
  const UserBranch(); // coverage:ignore-line
}
