// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lifecycle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// アプリのライフサイクル（フォアグラウンド/バックグラウンド等）を監視するプロバイダー

@ProviderFor(AppLifecycle)
final appLifecycleProvider = AppLifecycleProvider._();

/// アプリのライフサイクル（フォアグラウンド/バックグラウンド等）を監視するプロバイダー
final class AppLifecycleProvider
    extends $NotifierProvider<AppLifecycle, AppLifecycleState> {
  /// アプリのライフサイクル（フォアグラウンド/バックグラウンド等）を監視するプロバイダー
  AppLifecycleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLifecycleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLifecycleHash();

  @$internal
  @override
  AppLifecycle create() => AppLifecycle();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLifecycleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLifecycleState>(value),
    );
  }
}

String _$appLifecycleHash() => r'c8777dadfed4bef5df4f6dbb37a0c863d046216c';

/// アプリのライフサイクル（フォアグラウンド/バックグラウンド等）を監視するプロバイダー

abstract class _$AppLifecycle extends $Notifier<AppLifecycleState> {
  AppLifecycleState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppLifecycleState, AppLifecycleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppLifecycleState, AppLifecycleState>,
              AppLifecycleState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
