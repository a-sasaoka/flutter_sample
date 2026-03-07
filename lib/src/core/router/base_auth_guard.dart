import 'package:flutter_sample/src/core/router/app_router.dart';
import 'package:go_router/go_router.dart';

/// 認証状態に応じたリダイレクト先を判定する共通ヘルパー
class AuthGuardHelper {
  /// コンストラクタ
  const AuthGuardHelper();

  /// 認証状態と遷移先からリダイレクト先を決定する
  String? redirect({
    required bool isLoggedIn,
    required GoRouterState state,
  }) {
    // ログイン画面のパス
    final loginLocation = const LoginRoute().location;

    // ログイン不要画面のパス
    final publicPaths = {
      // ログイン画面
      const LoginRoute().location,
      // スプラッシュ画面
      const SplashRoute().location,
      // サインアップ画面
      const SignUpRoute().location,
    };

    // 遷移先がログイン画面かどうか
    final goingToLogin = state.uri.toString() == loginLocation;

    // 遷移先がログイン不要画面かどうか
    final path = state.uri.toString();
    final isPublic = publicPaths.contains(path);

    // 未ログイン時はログイン画面へ
    if (!isLoggedIn && !isPublic) {
      return loginLocation;
    }

    // ログイン済みかつログイン画面へ行こうとしている場合はホームへ
    if (isLoggedIn && goingToLogin) {
      return const HomeRoute().location;
    }

    // 条件に当てはまらなければ遷移をそのまま続行
    return null;
  }
}
