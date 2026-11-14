// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session_lock.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 認証セッションの読み書きを直列化するロックを提供するプロバイダ

@ProviderFor(authSessionLock)
final authSessionLockProvider = AuthSessionLockProvider._();

/// 認証セッションの読み書きを直列化するロックを提供するプロバイダ

final class AuthSessionLockProvider
    extends
        $FunctionalProvider<AuthSessionLock, AuthSessionLock, AuthSessionLock>
    with $Provider<AuthSessionLock> {
  /// 認証セッションの読み書きを直列化するロックを提供するプロバイダ
  AuthSessionLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authSessionLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authSessionLockHash();

  @$internal
  @override
  $ProviderElement<AuthSessionLock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthSessionLock create(Ref ref) {
    return authSessionLock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthSessionLock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthSessionLock>(value),
    );
  }
}

String _$authSessionLockHash() => r'6c3b102dfa76b64a90ea07306f080b4f594c4cc2';
