// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 認証方式（Firebase / 自前認証）に依存しないログイン状態を提供するプロバイダー

@ProviderFor(isAuthenticated)
final isAuthenticatedProvider = IsAuthenticatedProvider._();

/// 認証方式（Firebase / 自前認証）に依存しないログイン状態を提供するプロバイダー

final class IsAuthenticatedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 認証方式（Firebase / 自前認証）に依存しないログイン状態を提供するプロバイダー
  IsAuthenticatedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isAuthenticatedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isAuthenticatedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isAuthenticated(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isAuthenticatedHash() => r'a31798b5809b150c4e72e6c0589a56702a5436b8';

/// 独自認証モードでのログイン中ユーザーIDを提供するプロバイダー（未ログイン時はnull）

@ProviderFor(customUserId)
final customUserIdProvider = CustomUserIdProvider._();

/// 独自認証モードでのログイン中ユーザーIDを提供するプロバイダー（未ログイン時はnull）

final class CustomUserIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// 独自認証モードでのログイン中ユーザーIDを提供するプロバイダー（未ログイン時はnull）
  CustomUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customUserIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customUserIdHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return customUserId(ref);
  }
}

String _$customUserIdHash() => r'7ce07cf834565ae590a898055621326ccd162509';

/// 現在ログイン中のユーザーIDを提供するプロバイダー（未ログイン時はnull）

@ProviderFor(currentUserId)
final currentUserIdProvider = CurrentUserIdProvider._();

/// 現在ログイン中のユーザーIDを提供するプロバイダー（未ログイン時はnull）

final class CurrentUserIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// 現在ログイン中のユーザーIDを提供するプロバイダー（未ログイン時はnull）
  CurrentUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return currentUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentUserIdHash() => r'1f94c42d2696bc1ffcab63a92690f48bb928df05';

/// 認証関連の高レベルな操作（ログアウトなど）を提供するサービス

@ProviderFor(authService)
final authServiceProvider = AuthServiceProvider._();

/// 認証関連の高レベルな操作（ログアウトなど）を提供するサービス

final class AuthServiceProvider
    extends $FunctionalProvider<AuthService, AuthService, AuthService>
    with $Provider<AuthService> {
  /// 認証関連の高レベルな操作（ログアウトなど）を提供するサービス
  AuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authServiceHash();

  @$internal
  @override
  $ProviderElement<AuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthService create(Ref ref) {
    return authService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthService>(value),
    );
  }
}

String _$authServiceHash() => r'beba550f43a94a9aa331c70c1f5e371981d5d83f';
