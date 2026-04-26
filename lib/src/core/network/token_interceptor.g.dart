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

/// 再リクエスト（リトライ）用のDioインスタンスを提供するProvider
/// テスト時にモックへ差し替え可能にするために切り出し

@ProviderFor(retryDio)
final retryDioProvider = RetryDioProvider._();

/// 再リクエスト（リトライ）用のDioインスタンスを提供するProvider
/// テスト時にモックへ差し替え可能にするために切り出し

final class RetryDioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// 再リクエスト（リトライ）用のDioインスタンスを提供するProvider
  /// テスト時にモックへ差し替え可能にするために切り出し
  RetryDioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'retryDioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$retryDioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return retryDio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$retryDioHash() => r'8c75a1e5ad1d201e04db4c26b9f655a848b4784a';

/// トークンを自動で付与・更新するDioのインターセプター

@ProviderFor(tokenInterceptor)
final tokenInterceptorProvider = TokenInterceptorProvider._();

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

String _$tokenInterceptorHash() => r'62ef4495afcf37ce98c09b9e9d6f5931c39645c4';
