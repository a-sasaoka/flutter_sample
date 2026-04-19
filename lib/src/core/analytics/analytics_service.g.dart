// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Firebase Analytics のインスタンスを提供する Provider

@ProviderFor(firebaseAnalytics)
const firebaseAnalyticsProvider = FirebaseAnalyticsProvider._();

/// Firebase Analytics のインスタンスを提供する Provider

final class FirebaseAnalyticsProvider
    extends
        $FunctionalProvider<
          FirebaseAnalytics,
          FirebaseAnalytics,
          FirebaseAnalytics
        >
    with $Provider<FirebaseAnalytics> {
  /// Firebase Analytics のインスタンスを提供する Provider
  const FirebaseAnalyticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAnalyticsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAnalyticsHash();

  @$internal
  @override
  $ProviderElement<FirebaseAnalytics> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseAnalytics create(Ref ref) {
    return firebaseAnalytics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAnalytics value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAnalytics>(value),
    );
  }
}

String _$firebaseAnalyticsHash() => r'00a82f1fb02a87d9f2b3720ecfce305a80ae39da';

/// Analytics Service を Riverpod で提供

@ProviderFor(analyticsService)
const analyticsServiceProvider = AnalyticsServiceProvider._();

/// Analytics Service を Riverpod で提供

final class AnalyticsServiceProvider
    extends
        $FunctionalProvider<
          AnalyticsService,
          AnalyticsService,
          AnalyticsService
        >
    with $Provider<AnalyticsService> {
  /// Analytics Service を Riverpod で提供
  const AnalyticsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsServiceHash();

  @$internal
  @override
  $ProviderElement<AnalyticsService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AnalyticsService create(Ref ref) {
    return analyticsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyticsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyticsService>(value),
    );
  }
}

String _$analyticsServiceHash() => r'20332d0f7e201d5ec00bf6d6b39de54d761c020a';
