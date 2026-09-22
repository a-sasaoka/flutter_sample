// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_flags_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// フィーチャーフラグおよび動的バナーの状態を管理するNotifier

@ProviderFor(FeatureFlagsNotifier)
final featureFlagsProvider = FeatureFlagsNotifierProvider._();

/// フィーチャーフラグおよび動的バナーの状態を管理するNotifier
final class FeatureFlagsNotifierProvider
    extends $NotifierProvider<FeatureFlagsNotifier, FeatureFlags> {
  /// フィーチャーフラグおよび動的バナーの状態を管理するNotifier
  FeatureFlagsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featureFlagsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featureFlagsNotifierHash();

  @$internal
  @override
  FeatureFlagsNotifier create() => FeatureFlagsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeatureFlags value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeatureFlags>(value),
    );
  }
}

String _$featureFlagsNotifierHash() =>
    r'f7bf50c8e599ac767d33f6b4011ca3eec9cc1ff3';

/// フィーチャーフラグおよび動的バナーの状態を管理するNotifier

abstract class _$FeatureFlagsNotifier extends $Notifier<FeatureFlags> {
  FeatureFlags build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FeatureFlags, FeatureFlags>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FeatureFlags, FeatureFlags>,
              FeatureFlags,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
