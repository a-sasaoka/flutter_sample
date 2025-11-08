// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$homeRoute];

RouteBase get $homeRoute => GoRouteData.$route(
  path: '/',
  factory: $HomeRoute._fromState,
  routes: [
    GoRouteData.$route(path: 'settings', factory: $SettingsRoute._fromState),
    GoRouteData.$route(path: 'sample', factory: $SampleRoute._fromState),
    GoRouteData.$route(path: 'users', factory: $UserListRoute._fromState),
  ],
);

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SampleRoute on GoRouteData {
  static SampleRoute _fromState(GoRouterState state) => const SampleRoute();

  @override
  String get location => GoRouteData.$location('/sample');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $UserListRoute on GoRouteData {
  static UserListRoute _fromState(GoRouterState state) => const UserListRoute();

  @override
  String get location => GoRouteData.$location('/users');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 🌐 GoRouterのインスタンスをRiverpodで提供
///
/// 旧: `final routerProvider = Provider<GoRouter>((ref) { ... });`
/// 新: `@riverpod` アノテーションで自動生成される。

@ProviderFor(router)
const routerProvider = RouterProvider._();

/// 🌐 GoRouterのインスタンスをRiverpodで提供
///
/// 旧: `final routerProvider = Provider<GoRouter>((ref) { ... });`
/// 新: `@riverpod` アノテーションで自動生成される。

final class RouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// 🌐 GoRouterのインスタンスをRiverpodで提供
  ///
  /// 旧: `final routerProvider = Provider<GoRouter>((ref) { ... });`
  /// 新: `@riverpod` アノテーションで自動生成される。
  const RouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return router(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerHash() => r'51d215882c2b91f87e727ba03f2a39700a655e8c';
