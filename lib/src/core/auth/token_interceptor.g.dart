// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_interceptor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tokenInterceptor)
const tokenInterceptorProvider = TokenInterceptorProvider._();

final class TokenInterceptorProvider
    extends
        $FunctionalProvider<
          InterceptorsWrapper,
          InterceptorsWrapper,
          InterceptorsWrapper
        >
    with $Provider<InterceptorsWrapper> {
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

String _$tokenInterceptorHash() => r'0e38a1fbeb7cb1c76137c26af0dc8ed03b07e6db';
