import 'package:flutter_sample/src/app/router/app_router.dart';
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
    // ログイン不要画面のパス
    final publicPaths = {
      // ログイン画面
      const LoginRoute().location,
      // スプラッシュ画面
      const SplashRoute().location,
      // サインアップ画面
      const SignUpRoute().location,
    };

    // 認証済みの場合はアクセスさせない画面のパス
    final authPaths = {
      // ログイン画面
      const LoginRoute().location,
      // サインアップ画面
      const SignUpRoute().location,
    };

    // クエリパラメータの影響を受けないようにパスのみを取得する
    final path = state.uri.path;

    // 遷移先が認証関連の画面かどうか
    final goingToAuth = authPaths.contains(path);

    // 遷移先がログイン不要画面（パブリック）かどうか
    final isPublic = publicPaths.contains(path);

    // 未ログイン時はログイン画面へ
    if (!isLoggedIn && !isPublic) {
      return const LoginRoute().location;
    }

    // ログイン済みかつ認証関連画面へ行こうとしている場合はホームへ
    if (isLoggedIn && goingToAuth) {
      return const HomeRoute().location;
    }

    // 条件に当てはまらなければ遷移をそのまま続行
    return null;
  }
}
