// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_cache_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 画像キャッシュマネージャーを提供するプロバイダー（null の場合は DefaultCacheManager が使用されます）

@ProviderFor(imageCacheManager)
final imageCacheManagerProvider = ImageCacheManagerProvider._();

/// 画像キャッシュマネージャーを提供するプロバイダー（null の場合は DefaultCacheManager が使用されます）

final class ImageCacheManagerProvider
    extends
        $FunctionalProvider<
          BaseCacheManager?,
          BaseCacheManager?,
          BaseCacheManager?
        >
    with $Provider<BaseCacheManager?> {
  /// 画像キャッシュマネージャーを提供するプロバイダー（null の場合は DefaultCacheManager が使用されます）
  ImageCacheManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageCacheManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageCacheManagerHash();

  @$internal
  @override
  $ProviderElement<BaseCacheManager?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BaseCacheManager? create(Ref ref) {
    return imageCacheManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BaseCacheManager? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BaseCacheManager?>(value),
    );
  }
}

String _$imageCacheManagerHash() => r'90ab78e2eb3bfced8b6d648c58055348cbdbd6af';

/// ImageCacheService を提供するプロバイダー

@ProviderFor(imageCacheService)
final imageCacheServiceProvider = ImageCacheServiceProvider._();

/// ImageCacheService を提供するプロバイダー

final class ImageCacheServiceProvider
    extends
        $FunctionalProvider<
          ImageCacheService,
          ImageCacheService,
          ImageCacheService
        >
    with $Provider<ImageCacheService> {
  /// ImageCacheService を提供するプロバイダー
  ImageCacheServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageCacheServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageCacheServiceHash();

  @$internal
  @override
  $ProviderElement<ImageCacheService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImageCacheService create(Ref ref) {
    return imageCacheService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageCacheService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageCacheService>(value),
    );
  }
}

String _$imageCacheServiceHash() => r'c2398b08186c64482b85d66a4ab3329456146c78';
