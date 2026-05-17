import 'package:go_router/go_router.dart';

/// 認証状態に応じたリダイレクト先を判定する共通ヘルパー
class AuthGuardHelper {
  /// コンストラクタ
  const AuthGuardHelper({
    required this.loginLocation,
    required this.defaultLocation,
    required this.guestOnlyPaths,
    required this.alwaysPublicPaths,
  });

  /// ログイン画面のパス
  /// 未ログインユーザーを誘導する際に使用します。
  final String loginLocation;

  /// ログイン成功時などのデフォルトの遷移先（ホーム画面など）
  /// ログイン済みのユーザーがゲスト専用画面にアクセスした際の戻り先として使用します。
  final String defaultLocation;

  /// 【未ログイン時のみ】アクセス可能な画面のパス（ゲスト専用）
  /// ログイン画面、サインアップ画面、パスワードリセット画面などが該当します。
  /// ログイン済みユーザーがアクセスした場合は [defaultLocation] へリダイレクトします。
  final Set<String> guestOnlyPaths;

  /// 【常に】誰でもアクセス可能な画面のパス
  /// スプラッシュ画面、アプリの使い方、利用規約などが該当します。
  /// ログイン状態に関わらず、常にアクセスを許可します。
  final Set<String> alwaysPublicPaths;

  /// 認証状態と遷移先からリダイレクト先を決定する
  ///
  /// 優先順位：
  /// 1. 常に公開されている画面 ([alwaysPublicPaths]) なら、そのまま遷移
  /// 2. 未ログインの場合：
  ///    - ゲスト専用画面 ([guestOnlyPaths]) なら、そのまま遷移
  ///    - それ以外の画面なら、[loginLocation] へリダイレクト（元の目的地を from に保持）
  /// 3. ログイン済みの場合：
  ///    - ゲスト専用画面 ([guestOnlyPaths]) なら、[defaultLocation]（または from）へリダイレクト
  ///    - それ以外の画面なら、そのまま遷移
  String? redirect({
    required bool isLoggedIn,
    required GoRouterState state,
  }) {
    // クエリパラメータの影響を受けないようにパスのみを取得する
    final path = state.uri.path;

    // 1. 常に公開されている画面なら、何もせずそのまま遷移させる
    if (alwaysPublicPaths.contains(path)) {
      return null;
    }

    final isGuestOnly = guestOnlyPaths.contains(path);

    // 2. 未ログイン状態の判定
    if (!isLoggedIn) {
      // ゲスト専用画面ならOK、それ以外（認証必須画面）ならログイン画面へ
      if (isGuestOnly) {
        return null;
      }

      // 元々行こうとしていた場所を from パラメータに持たせてログイン画面へ
      return Uri(
        path: loginLocation,
        queryParameters: {
          'from': state.uri.toString(),
        },
      ).toString();
    }

    // 3. ログイン済み状態の判定
    // ここに来る時点で isLoggedIn は必ず true です。
    // ゲスト専用画面（ログイン画面など）へ行こうとしている場合はリダイレクトします。
    if (isGuestOnly) {
      // from パラメータ（元々の目的地）があればそこへ、なければデフォルト（ホーム）へ
      final from = state.uri.queryParameters['from'];

      // 🛡️ セキュリティバリデーション
      // 1. from が存在し、
      // 2. 外部サイトへのリダイレクトではない（/から始まり、//で始まらない内部パス）こと
      // 3. 遷移先がゲスト専用画面ではない（無限ループ防止）こと
      // を確認します。
      if (from != null &&
          from.startsWith('/') &&
          !from.startsWith('//') &&
          !guestOnlyPaths.contains(Uri.parse(from).path)) {
        return from;
      }

      return defaultLocation;
    }

    // それ以外の画面（認証必須画面）ならOK、そのまま遷移
    return null;
  }
}
