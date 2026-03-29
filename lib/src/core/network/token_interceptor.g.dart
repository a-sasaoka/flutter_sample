// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_interceptor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// テストで Notifier の内部構造 (_element) によるエラーを回避するため、
/// Notifier インスタンスを直接提供するだけの Provider を定義します。
/// これにより、テスト時は単なる Mock オブジェクトに差し替え可能になります。

@ProviderFor(tokenStorageInternal)
const tokenStorageInternalProvider = TokenStorageInternalProvider._();

/// テストで Notifier の内部構造 (_element) によるエラーを回避するため、
/// Notifier インスタンスを直接提供するだけの Provider を定義します。
/// これにより、テスト時は単なる Mock オブジェクトに差し替え可能になります。

final class TokenStorageInternalProvider
    extends $FunctionalProvider<TokenStorage, TokenStorage, TokenStorage>
    with $Provider<TokenStorage> {
  /// テストで Notifier の内部構造 (_element) によるエラーを回避するため、
  /// Notifier インスタンスを直接提供するだけの Provider を定義します。
  /// これにより、テスト時は単なる Mock オブジェクトに差し替え可能になります。
  const TokenStorageInternalProvider._()
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

/// テストで Notifier の内部構造 (_element) によるエラーを回避するため、
/// Notifier インスタンスを直接提供するだけの Provider を定義します。
/// これにより、テスト時は単なる Mock オブジェクトに差し替え可能になります。

@ProviderFor(authRepositoryInternal)
const authRepositoryInternalProvider = AuthRepositoryInternalProvider._();

/// テストで Notifier の内部構造 (_element) によるエラーを回避するため、
/// Notifier インスタンスを直接提供するだけの Provider を定義します。
/// これにより、テスト時は単なる Mock オブジェクトに差し替え可能になります。

final class AuthRepositoryInternalProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// テストで Notifier の内部構造 (_element) によるエラーを回避するため、
  /// Notifier インスタンスを直接提供するだけの Provider を定義します。
  /// これにより、テスト時は単なる Mock オブジェクトに差し替え可能になります。
  const AuthRepositoryInternalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryInternalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryInternalHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepositoryInternal(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryInternalHash() =>
    r'a1ea2139ac0b1614d6f30d1aa4c49f0155142780';

/// 再リクエスト（リトライ）用のDioインスタンスを提供するProvider
/// テスト時にモックへ差し替え可能にするために切り出し

@ProviderFor(retryDio)
const retryDioProvider = RetryDioProvider._();

/// 再リクエスト（リトライ）用のDioインスタンスを提供するProvider
/// テスト時にモックへ差し替え可能にするために切り出し

final class RetryDioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// 再リクエスト（リトライ）用のDioインスタンスを提供するProvider
  /// テスト時にモックへ差し替え可能にするために切り出し
  const RetryDioProvider._()
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

String _$tokenInterceptorHash() => r'f7cd6c161415f624b2c9b324902ff39001cf3952';
