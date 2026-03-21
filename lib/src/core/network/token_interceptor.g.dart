// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_interceptor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// トークンを自動で付与・更新するDioのインターセプター

@ProviderFor(tokenInterceptor)
const tokenInterceptorProvider = TokenInterceptorProvider._();

/// トークンを自動で付与・更新するDioのインターセプター

final class TokenInterceptorProvider
    extends
        $FunctionalProvider<
          InterceptorsWrapper,
          InterceptorsWrapper,
          InterceptorsWrapper
        >
    with $Provider<InterceptorsWrapper> {
  /// トークンを自動で付与・更新するDioのインターセプター
  const TokenInterceptorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tokenInterceptorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tokenInterceptorHash();

  @$internal
  @override
  $ProviderElement<InterceptorsWrapper> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InterceptorsWrapper create(Ref ref) {
    return tokenInterceptor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InterceptorsWrapper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InterceptorsWrapper>(value),
    );
  }
}

String _$tokenInterceptorHash() => r'6dde44edabe83b1673a3d14eb83079a866679e8d';
