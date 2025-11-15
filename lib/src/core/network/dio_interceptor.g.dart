// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_interceptor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Dioインターセプタプロバイダ

@ProviderFor(dioInterceptor)
const dioInterceptorProvider = DioInterceptorProvider._();

/// Dioインターセプタプロバイダ

final class DioInterceptorProvider
    extends
        $FunctionalProvider<
          InterceptorsWrapper,
          InterceptorsWrapper,
          InterceptorsWrapper
        >
    with $Provider<InterceptorsWrapper> {
  /// Dioインターセプタプロバイダ
  const DioInterceptorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioInterceptorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioInterceptorHash();

  @$internal
  @override
  $ProviderElement<InterceptorsWrapper> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InterceptorsWrapper create(Ref ref) {
    return dioInterceptor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InterceptorsWrapper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InterceptorsWrapper>(value),
    );
  }
}

String _$dioInterceptorHash() => r'64385007b53613f601d394bd549b22e43028981c';
