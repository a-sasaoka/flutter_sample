// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 追加の認証インターセプターを提供するプロバイダー（デフォルトは空リスト）
/// Core層では特定の機能に依存しないため、App/Feature層にてオーバーライドして注入します

@ProviderFor(authInterceptors)
final authInterceptorsProvider = AuthInterceptorsProvider._();

/// 追加の認証インターセプターを提供するプロバイダー（デフォルトは空リスト）
/// Core層では特定の機能に依存しないため、App/Feature層にてオーバーライドして注入します

final class AuthInterceptorsProvider
    extends
        $FunctionalProvider<
          List<Interceptor>,
          List<Interceptor>,
          List<Interceptor>
        >
    with $Provider<List<Interceptor>> {
  /// 追加の認証インターセプターを提供するプロバイダー（デフォルトは空リスト）
  /// Core層では特定の機能に依存しないため、App/Feature層にてオーバーライドして注入します
  AuthInterceptorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authInterceptorsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authInterceptorsHash();

  @$internal
  @override
  $ProviderElement<List<Interceptor>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<Interceptor> create(Ref ref) {
    return authInterceptors(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Interceptor> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Interceptor>>(value),
    );
  }
}

String _$authInterceptorsHash() => r'd99730a2c35f8ec3cefca55295809563d23a8a40';

/// 共通Dioインスタンスを提供するProvider
///
/// - Base URLやタイムアウトを設定
/// - インターセプタでログ出力
/// - トークン認証などもオーバーライドによって組み込み可能

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// 共通Dioインスタンスを提供するProvider
///
/// - Base URLやタイムアウトを設定
/// - インターセプタでログ出力
/// - トークン認証などもオーバーライドによって組み込み可能

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// 共通Dioインスタンスを提供するProvider
  ///
  /// - Base URLやタイムアウトを設定
  /// - インターセプタでログ出力
  /// - トークン認証などもオーバーライドによって組み込み可能
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

String _$dioHash() => r'574e45eb05e8e7ee1180fb89d1d60cb529bf288a';

/// 認証や再リクエスト用のプレーンなDioインスタンスを提供するProvider
///
/// メインの `dioProvider` と同じ基本設定・ログ出力を適用しますが、
/// 無限ループを防ぐためトークンのインターセプターは含まれません。

@ProviderFor(baseDio)
final baseDioProvider = BaseDioProvider._();

/// 認証や再リクエスト用のプレーンなDioインスタンスを提供するProvider
///
/// メインの `dioProvider` と同じ基本設定・ログ出力を適用しますが、
/// 無限ループを防ぐためトークンのインターセプターは含まれません。

final class BaseDioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// 認証や再リクエスト用のプレーンなDioインスタンスを提供するProvider
  ///
  /// メインの `dioProvider` と同じ基本設定・ログ出力を適用しますが、
  /// 無限ループを防ぐためトークンのインターセプターは含まれません。
  BaseDioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'baseDioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$baseDioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return baseDio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$baseDioHash() => r'5a1c2ac99d857affa439a85383859c40b718aec5';
