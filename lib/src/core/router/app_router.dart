// Riverpod + GoRouter + アノテーション対応版
// GoRouterBuilderによる型安全なルーティング + riverpod_generator対応

import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/auth/auth_guard.dart';
import 'package:flutter_sample/src/core/widgets/home_screen.dart';
import 'package:flutter_sample/src/core/widgets/not_found_screen.dart';
import 'package:flutter_sample/src/core/widgets/settings_screen.dart';
import 'package:flutter_sample/src/features/auth/presentation/login_screen.dart';
import 'package:flutter_sample/src/features/sample_feature/presentation/sample_screen.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_screen.dart';
import 'package:flutter_sample/src/features/user/presentation/user_list_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// 🏠 ホーム画面ルート
@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [
    TypedGoRoute<SettingsRoute>(path: 'settings'),
    TypedGoRoute<SampleRoute>(path: 'sample'),
    TypedGoRoute<UserListRoute>(path: 'users'),
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

/// 👥 ユーザー一覧画面ルート
class UserListRoute extends GoRouteData with $UserListRoute {
  /// コンストラクタ
  const UserListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const UserListScreen();
  }
}

/// 🔐 ログイン画面ルート
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  /// コンストラクタ
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }
}

/// スプラッシュ画面ルート
@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with $SplashRoute {
  /// コンストラクタ
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SplashScreen();
  }
}

/// 🌐 GoRouterのインスタンスをRiverpodで提供
@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    routes: $appRoutes,
    redirect: (context, state) => authGuard(ref, state),
    errorBuilder: (context, state) =>
        NotFoundScreen(unknownPath: state.uri.toString()),
    debugLogDiagnostics: true,
  );
}
