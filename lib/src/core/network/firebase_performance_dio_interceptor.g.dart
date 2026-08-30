// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_performance_dio_interceptor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// FirebasePerformanceDioInterceptor を提供するプロバイダー

@ProviderFor(firebasePerformanceDioInterceptor)
final firebasePerformanceDioInterceptorProvider =
    FirebasePerformanceDioInterceptorProvider._();

/// FirebasePerformanceDioInterceptor を提供するプロバイダー

final class FirebasePerformanceDioInterceptorProvider
    extends
        $FunctionalProvider<
          FirebasePerformanceDioInterceptor,
          FirebasePerformanceDioInterceptor,
          FirebasePerformanceDioInterceptor
        >
    with $Provider<FirebasePerformanceDioInterceptor> {
  /// FirebasePerformanceDioInterceptor を提供するプロバイダー
  FirebasePerformanceDioInterceptorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebasePerformanceDioInterceptorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$firebasePerformanceDioInterceptorHash();

  @$internal
  @override
  $ProviderElement<FirebasePerformanceDioInterceptor> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebasePerformanceDioInterceptor create(Ref ref) {
    return firebasePerformanceDioInterceptor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebasePerformanceDioInterceptor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebasePerformanceDioInterceptor>(
        value,
      ),
    );
  }
}

String _$firebasePerformanceDioInterceptorHash() =>
    r'7c86d10992e901268de4f0f8668e499a7c16f1e8';
