// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retry_interceptor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [RetryInterceptor] を提供するプロバイダー

@ProviderFor(retryInterceptor)
final retryInterceptorProvider = RetryInterceptorProvider._();

/// [RetryInterceptor] を提供するプロバイダー

final class RetryInterceptorProvider
    extends $FunctionalProvider<Interceptor, Interceptor, Interceptor>
    with $Provider<Interceptor> {
  /// [RetryInterceptor] を提供するプロバイダー
  RetryInterceptorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'retryInterceptorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$retryInterceptorHash();

  @$internal
  @override
  $ProviderElement<Interceptor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Interceptor create(Ref ref) {
    return retryInterceptor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Interceptor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Interceptor>(value),
    );
  }
}

String _$retryInterceptorHash() => r'1c4063d9c774c370aae59055dd4f93a9f05bc308';
