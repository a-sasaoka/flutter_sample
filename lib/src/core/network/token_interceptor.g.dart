// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_interceptor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [TokenRefreshCallback] を提供するプロバイダ
///
/// Core層では具体的な実装を持たないため、デフォルトでは `UnimplementedError` を投げます。
/// アプリ起動時の最上位の `ProviderScope` (overrides) にて、
/// Feature層のリフレッシュ処理（例: authRepositoryProvider の refreshToken メソッド）
/// でオーバーライドして使用してください

@ProviderFor(tokenRefreshCallback)
final tokenRefreshCallbackProvider = TokenRefreshCallbackProvider._();

/// [TokenRefreshCallback] を提供するプロバイダ
///
/// Core層では具体的な実装を持たないため、デフォルトでは `UnimplementedError` を投げます。
/// アプリ起動時の最上位の `ProviderScope` (overrides) にて、
/// Feature層のリフレッシュ処理（例: authRepositoryProvider の refreshToken メソッド）
/// でオーバーライドして使用してください

final class TokenRefreshCallbackProvider
    extends
        $FunctionalProvider<
          TokenRefreshCallback,
          TokenRefreshCallback,
          TokenRefreshCallback
        >
    with $Provider<TokenRefreshCallback> {
  /// [TokenRefreshCallback] を提供するプロバイダ
  ///
  /// Core層では具体的な実装を持たないため、デフォルトでは `UnimplementedError` を投げます。
  /// アプリ起動時の最上位の `ProviderScope` (overrides) にて、
  /// Feature層のリフレッシュ処理（例: authRepositoryProvider の refreshToken メソッド）
  /// でオーバーライドして使用してください
  TokenRefreshCallbackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tokenRefreshCallbackProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tokenRefreshCallbackHash();

  @$internal
  @override
  $ProviderElement<TokenRefreshCallback> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TokenRefreshCallback create(Ref ref) {
    return tokenRefreshCallback(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenRefreshCallback value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenRefreshCallback>(value),
    );
  }
}

String _$tokenRefreshCallbackHash() =>
    r'6ab82d6c3982c2d325c5e1c1e44eed4f0a9e43c2';

/// テストで Notifier の内部構造 (_element) によるエラーを回避するため、
/// Notifier インスタンスを直接提供するだけの Provider を定義します。
/// これにより、テスト時は単なる Mock オブジェクトに差し替え可能になります。

@ProviderFor(tokenStorageInternal)
final tokenStorageInternalProvider = TokenStorageInternalProvider._();

/// テストで Notifier の内部構造 (_element) によるエラーを回避するため、
/// Notifier インスタンスを直接提供するだけの Provider を定義します。
/// これにより、テスト時は単なる Mock オブジェクトに差し替え可能になります。

final class TokenStorageInternalProvider
    extends $FunctionalProvider<TokenStorage, TokenStorage, TokenStorage>
    with $Provider<TokenStorage> {
  /// テストで Notifier の内部構造 (_element) によるエラーを回避するため、
  /// Notifier インスタンスを直接提供するだけの Provider を定義します。
  /// これにより、テスト時は単なる Mock オブジェクトに差し替え可能になります。
  TokenStorageInternalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tokenStorageInternalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tokenStorageInternalHash();

  @$internal
  @override
  $ProviderElement<TokenStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TokenStorage create(Ref ref) {
    return tokenStorageInternal(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenStorage>(value),
    );
  }
}

String _$tokenStorageInternalHash() =>
    r'3e0364f9cdf9fc50fa6eb985833831eb3f1557e8';

/// トークンを自動で付与・更新するDioのインターセプター

@ProviderFor(tokenInterceptor)
final tokenInterceptorProvider = TokenInterceptorProvider._();

/// トークンを自動で付与・更新するDioのインターセプター

final class TokenInterceptorProvider
    extends $FunctionalProvider<Interceptor, Interceptor, Interceptor>
    with $Provider<Interceptor> {
  /// トークンを自動で付与・更新するDioのインターセプター
  TokenInterceptorProvider._()
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
  $ProviderElement<Interceptor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Interceptor create(Ref ref) {
    return tokenInterceptor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Interceptor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Interceptor>(value),
    );
  }
}

String _$tokenInterceptorHash() => r'1a72ec73ce9f55929489e9a0b0b175c88d879dfa';
