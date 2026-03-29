// APIレスポンスなどを簡易的にキャッシュする仕組み

import 'dart:convert';

import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cache_manager.g.dart';

/// キャッシュマネージャープロバイダー
@Riverpod(keepAlive: true)
CacheManager cacheManager(Ref ref) {
  return CacheManager._(ref);
}

/// キャッシュマネージャー
class CacheManager {
  /// コンストラクタ
  CacheManager._(this.ref);

  static const _cacheDuration = Duration(minutes: 10);
  static const _keyTimestamp = 'timestamp';
  static const _keyData = 'data';

  /// RiverpodのRef
  final Ref ref;

  /// キャッシュを保存
  Future<void> save(String key, dynamic value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final data = {
      _keyTimestamp: DateTime.now().millisecondsSinceEpoch,
      _keyData: value,
    };
    await prefs.setString(key, jsonEncode(data));
  }

  /// キャッシュを取得（期限切れならnull）
  Future<dynamic> get(String key) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final raw = await prefs.getString(key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        decoded[_keyTimestamp] as int,
      );
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        await prefs.remove(key);
        return null; // キャッシュ期限切れ
      }
      return decoded[_keyData];
    } on Object catch (_) {
      // JSONパースエラーや型の不一致などが起きた場合は、キャッシュが壊れているとみなして削除
      await prefs.remove(key);
      return null;
    }
  }

  /// キャッシュを削除
  Future<void> clear(String key) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.remove(key);
  }
}
