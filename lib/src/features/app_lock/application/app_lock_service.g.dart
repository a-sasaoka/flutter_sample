// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lock_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 🔐 アプリロックのロジックと状態（sealed クラス）を管理する AsyncNotifier

@ProviderFor(AppLockService)
final appLockServiceProvider = AppLockServiceProvider._();

/// 🔐 アプリロックのロジックと状態（sealed クラス）を管理する AsyncNotifier
final class AppLockServiceProvider
    extends $AsyncNotifierProvider<AppLockService, AppLockState> {
  /// 🔐 アプリロックのロジックと状態（sealed クラス）を管理する AsyncNotifier
  AppLockServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockServiceHash();

  @$internal
  @override
  AppLockService create() => AppLockService();
}

String _$appLockServiceHash() => r'0796d62712ee82e85e6ebd5efad40b4922d633af';

/// 🔐 アプリロックのロジックと状態（sealed クラス）を管理する AsyncNotifier

abstract class _$AppLockService extends $AsyncNotifier<AppLockState> {
  FutureOr<AppLockState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppLockState>, AppLockState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppLockState>, AppLockState>,
              AsyncValue<AppLockState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
