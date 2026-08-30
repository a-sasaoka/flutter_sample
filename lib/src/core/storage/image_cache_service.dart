import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'image_cache_service.g.dart';

/// 画像キャッシュ管理サービス
class ImageCacheService {
  /// コンストラクタ
  const ImageCacheService({
    required this.talker,
    this.cacheManager,
  });

  /// ロガー
  final Talker talker;

  /// キャッシュマネージャー（テスト等のモック注入用）
  final BaseCacheManager? cacheManager;

  /// メモリおよびディスク上の画像キャッシュを一括クリア
  Future<void> clearCache() async {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final manager = cacheManager ?? DefaultCacheManager();
      await manager.emptyCache();

      talker.debug('🖼️ Image cache cleared successfully.');
    } on Object catch (e, st) {
      talker.handle(e, st, 'Failed to clear image cache');
      rethrow;
    }
  }
}

/// 画像キャッシュマネージャーを提供するプロバイダー（null の場合は DefaultCacheManager が使用されます）
@Riverpod(keepAlive: true)
BaseCacheManager? imageCacheManager(Ref ref) {
  return null;
}

/// ImageCacheService を提供するプロバイダー
@Riverpod(keepAlive: true)
ImageCacheService imageCacheService(Ref ref) {
  return ImageCacheService(
    talker: ref.watch(loggerProvider),
    cacheManager: ref.watch(imageCacheManagerProvider),
  );
}
