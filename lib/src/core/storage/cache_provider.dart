// lib/src/core/storage/cache_provider.dart

import 'package:flutter_sample/src/core/storage/cache_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cache_provider.g.dart';

/// キャッシュマネージャープロバイダー
@Riverpod(keepAlive: true)
CacheManager cacheManager(Ref ref) {
  return CacheManager(ref);
}
