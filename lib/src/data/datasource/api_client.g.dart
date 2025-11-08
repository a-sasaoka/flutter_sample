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
const dioProvider = DioProvider._();

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
  const DioProvider._()
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

String _$dioHash() => r'd6596996b8eb29771ffaf84ca47c5b6b994a2985';

/// ApiClient を Riverpod 経由で提供する Provider
///
/// `ref.watch(apiClientProvider)` でどこからでも取得可能。

@ProviderFor(apiClient)
const apiClientProvider = ApiClientProvider._();

/// ApiClient を Riverpod 経由で提供する Provider
///
/// `ref.watch(apiClientProvider)` でどこからでも取得可能。

final class ApiClientProvider
    extends $FunctionalProvider<ApiClient, ApiClient, ApiClient>
    with $Provider<ApiClient> {
  /// ApiClient を Riverpod 経由で提供する Provider
  ///
  /// `ref.watch(apiClientProvider)` でどこからでも取得可能。
  const ApiClientProvider._()
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

String _$apiClientHash() => r'740a74da0b912aac1c8773d0a78295c2b4898a55';
