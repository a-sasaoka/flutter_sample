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

/// 開発者向けPush通知・ディープリンク検証デモ画面のルート
@TypedGoRoute<PushNotificationDemoRoute>(path: '/dev-tools/notification')
class PushNotificationDemoRoute extends GoRouteData
    with $PushNotificationDemoRoute {
  /// コンストラクタ
  const PushNotificationDemoRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const PushNotificationDemoScreen();
  }
}

/// 開発者向け画像キャッシュデモ画面のルート
@TypedGoRoute<ImageCacheDemoRoute>(path: '/dev-tools/image-cache')
class ImageCacheDemoRoute extends GoRouteData with $ImageCacheDemoRoute {
  /// コンストラクタ
  const ImageCacheDemoRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ImageCacheDemoScreen();
  }
}
