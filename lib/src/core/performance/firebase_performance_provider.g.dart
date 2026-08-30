// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_performance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Firebase Performance Monitoring のインスタンスを提供するプロバイダー（未初期化時は null）

@ProviderFor(firebasePerformance)
final firebasePerformanceProvider = FirebasePerformanceProvider._();

/// Firebase Performance Monitoring のインスタンスを提供するプロバイダー（未初期化時は null）

final class FirebasePerformanceProvider
    extends
        $FunctionalProvider<
          FirebasePerformance?,
          FirebasePerformance?,
          FirebasePerformance?
        >
    with $Provider<FirebasePerformance?> {
  /// Firebase Performance Monitoring のインスタンスを提供するプロバイダー（未初期化時は null）
  FirebasePerformanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebasePerformanceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebasePerformanceHash();

  @$internal
  @override
  $ProviderElement<FirebasePerformance?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebasePerformance? create(Ref ref) {
    return firebasePerformance(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebasePerformance? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebasePerformance?>(value),
    );
  }
}

String _$firebasePerformanceHash() =>
    r'44fe8377b72481085cda8c615b9d77e55c664370';
