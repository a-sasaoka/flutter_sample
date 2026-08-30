// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// PerformanceService を提供するプロバイダー

@ProviderFor(performanceService)
final performanceServiceProvider = PerformanceServiceProvider._();

/// PerformanceService を提供するプロバイダー

final class PerformanceServiceProvider
    extends
        $FunctionalProvider<
          PerformanceService,
          PerformanceService,
          PerformanceService
        >
    with $Provider<PerformanceService> {
  /// PerformanceService を提供するプロバイダー
  PerformanceServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'performanceServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$performanceServiceHash();

  @$internal
  @override
  $ProviderElement<PerformanceService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PerformanceService create(Ref ref) {
    return performanceService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PerformanceService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PerformanceService>(value),
    );
  }
}

String _$performanceServiceHash() =>
    r'fecb1a05584add681a973ec8c8bc86ab8092ca06';
