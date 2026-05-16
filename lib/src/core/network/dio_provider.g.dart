// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 共通Dioインスタンスを提供するProvider
///
/// - Base URLやタイムアウトを設定
/// - インターセプタでログ出力
/// - トークン認証もここで組み込み

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// 共通Dioインスタンスを提供するProvider
///
/// - Base URLやタイムアウトを設定
/// - インターセプタでログ出力
/// - トークン認証もここで組み込み

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// 共通Dioインスタンスを提供するProvider
  ///
  /// - Base URLやタイムアウトを設定
  /// - インターセプタでログ出力
  /// - トークン認証もここで組み込み
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

String _$dioHash() => r'8703fa1677b9ea61497315a9e885376cc98ea956';

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
