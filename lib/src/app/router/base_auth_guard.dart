import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:flutter_sample/src/features/splash/presentation/splash_state_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

/// スプラッシュやオンボーディングなど、ログイン状態に依存しない、または共通の初期状態判定を行う共通関数
String? checkBaseRedirect({
  required Ref ref,
  required GoRouterState state,
  required bool isLoggedIn,
}) {
  // 1. スプラッシュ画面の表示が完了していない場合は、強制的にスプラッシュ画面にとどまる
  final isSplashFinished = ref.read(splashStateProvider);
  if (!isSplashFinished) {
    return const SplashRoute().location;
  }

  // 2. オンボーディングの状態を取得
  final onboardingState = ref.read(onboardingProvider);
  final onboardingLocation = const OnboardingRoute().location;

  // エラー発生時はオンボーディング未完了として処理する
  if (onboardingState.hasError) {
    if (state.uri.path != onboardingLocation) {
      return onboardingLocation;
    }
    return null;
  }

  // オンボーディングデータの読み込み中はスプラッシュ画面へ案内する
  // ただし、すでにオンボーディング画面にいる場合はリダイレクトしない
  if (onboardingState.isLoading) {
    if (state.uri.path != onboardingLocation) {
      return const SplashRoute().location;
    }
    return null;
  }

  final isOnboardingCompleted = onboardingState.value ?? false;

  // 3. オンボーディングが未完了の場合はオンボーディング画面へリダイレクト
  if (!isOnboardingCompleted && state.uri.path != onboardingLocation) {
    return onboardingLocation;
  }

  // 4. すでにオンボーディング完了済みでオンボーディング画面にいる場合はリダイレクト
  if (isOnboardingCompleted && state.uri.path == onboardingLocation) {
    return isLoggedIn
        ? const HomeRoute().location
        : const LoginRoute().location;
  }

  // 5. スプラッシュ表示が完了しており、かつ現在スプラッシュ画面にいる場合は、
  // ログイン状態に応じた適切な画面（ホームまたはログイン）へリダイレクトする
  if (state.uri.path == const SplashRoute().location) {
    return isLoggedIn
        ? const HomeRoute().location
        : const LoginRoute().location;
  }

  return null;
}
