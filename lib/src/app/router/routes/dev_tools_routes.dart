// coverage:ignore-file
part of '../app_router.dart';

/// 開発者向けストレージ確認・編集画面のルート
@TypedGoRoute<DeveloperStorageRoute>(path: '/dev-tools/storage')
class DeveloperStorageRoute extends GoRouteData with $DeveloperStorageRoute {
  /// コンストラクタ
  const DeveloperStorageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DeveloperStorageScreen();
  }
}

/// 開発者向けLottieアニメーションデモ画面のルート
@TypedGoRoute<DeveloperLottieRoute>(path: '/dev-tools/lottie')
class DeveloperLottieRoute extends GoRouteData with $DeveloperLottieRoute {
  /// コンストラクタ
  const DeveloperLottieRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LottieDemoScreen();
  }
}
