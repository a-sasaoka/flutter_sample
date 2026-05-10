// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 共通Dioインスタンスを提供するProvider
///
/// - Base URLやタイムアウトを設定
/// - インターセプタでログ出力
/// - 必要に応じてトークン認証もここで実装可能

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// 共通Dioインスタンスを提供するProvider
///
/// - Base URLやタイムアウトを設定
/// - インターセプタでログ出力
/// - 必要に応じてトークン認証もここで実装可能

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// 共通Dioインスタンスを提供するProvider
  ///
  /// - Base URLやタイムアウトを設定
  /// - インターセプタでログ出力
  /// - 必要に応じてトークン認証もここで実装可能
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'07166d399c57f89d76727fdf2c62d4b2e235de1c';

/// ApiClient を Riverpod 経由で提供する Provider

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

/// ApiClient を Riverpod 経由で提供する Provider

final class ApiClientProvider
    extends $FunctionalProvider<ApiClient, ApiClient, ApiClient>
    with $Provider<ApiClient> {
  /// ApiClient を Riverpod 経由で提供する Provider
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<ApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiClient create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiClient>(value),
    );
  }
}

String _$apiClientHash() => r'5ac0fa46e426cc68396727c752a17e43343ed504';
