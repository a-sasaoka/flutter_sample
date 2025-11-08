import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/widgets/home_screen.dart';
import 'package:flutter_sample/src/core/widgets/not_found_screen.dart';
import 'package:flutter_sample/src/core/widgets/settings_screen.dart';
import 'package:flutter_sample/src/features/sample_feature/presentation/sample_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'app_router.g.dart';

/// 🏠 ホーム画面ルート
@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [
    TypedGoRoute<SettingsRoute>(path: 'settings'),
    TypedGoRoute<SampleRoute>(path: 'sample'),
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

/// 🧪 サンプル画面ルート
class SampleRoute extends GoRouteData with $SampleRoute {
  /// コンストラクタ
  const SampleRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SampleScreen();
  }
}

/// ❌ ページが見つからない場合
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: $appRoutes, // ← 自動生成ルート一覧
    errorBuilder: (context, state) =>
        NotFoundScreen(unknownPath: state.uri.toString()),
    debugLogDiagnostics: true,
  );
});
