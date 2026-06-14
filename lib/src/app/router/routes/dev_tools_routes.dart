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
