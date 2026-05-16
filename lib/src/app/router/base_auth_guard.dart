import 'package:go_router/go_router.dart';

/// 認証状態に応じたリダイレクト先を判定する共通ヘルパー
class AuthGuardHelper {
  /// コンストラクタ
  const AuthGuardHelper({
    required this.loginLocation,
    required this.homeLocation,
    this.splashLocation,
    this.signUpLocation,
    this.resetPasswordLocation,
  });

  /// ログイン画面のパス
  final String loginLocation;

  /// ホーム画面のパス
  final String homeLocation;

  /// スプラッシュ画面のパス（オプション）
  final String? splashLocation;

  /// サインアップ画面のパス（オプション）
  final String? signUpLocation;

  /// パスワードリセット画面のパス（オプション）
  final String? resetPasswordLocation;

  /// 認証状態と遷移先からリダイレクト先を決定する
  String? redirect({
    required bool isLoggedIn,
    required GoRouterState state,
  }) {
    // ログイン不要画面のパス（セットとして管理）
    final publicPaths = {
      loginLocation,
      if (splashLocation != null) splashLocation,
      if (signUpLocation != null) signUpLocation,
      if (resetPasswordLocation != null) resetPasswordLocation,
    };

    // 認証済みの場合はアクセスさせない画面のパス（再ログイン防止用）
    final authPaths = {
      loginLocation,
      if (signUpLocation != null) signUpLocation,
    };

    // クエリパラメータの影響を受けないようにパスのみを取得する
    final path = state.uri.path;

    // 遷移先が認証関連の画面かどうか
    final goingToAuth = authPaths.contains(path);

    // 遷移先がログイン不要画面（パブリック）かどうか
    final isPublic = publicPaths.contains(path);

    // 未ログイン時はログイン画面へ
    if (!isLoggedIn && !isPublic) {
      return loginLocation;
    }

    // ログイン済みかつ認証関連画面へ行こうとしている場合はホームへ
    if (isLoggedIn && goingToAuth) {
      return homeLocation;
    }

    // 条件に当てはまらなければ遷移をそのまま続行
    return null;
  }
}
