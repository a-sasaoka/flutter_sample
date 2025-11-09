// lib/src/core/storage/cache_manager.dart
// APIレスポンスなどを簡易的にキャッシュする仕組み

import 'dart:convert';

import 'package:flutter_sample/src/core/config/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// キャッシュマネージャー
class CacheManager {
  /// コンストラクタ
  CacheManager(this.ref);

  static const _cacheDuration = Duration(minutes: 10);

  /// RiverpodのRef
  final Ref ref;

  /// キャッシュを保存
  Future<void> save(String key, dynamic value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final data = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': value,
    };
    await prefs.setString(key, jsonEncode(data));
  }

  /// キャッシュを取得（期限切れならnull）
  Future<dynamic> get(String key) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(key);
    if (raw == null) return null;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      decoded['timestamp'] as int,
    );
    if (DateTime.now().difference(timestamp) > _cacheDuration) {
      await prefs.remove(key);
      return null; // キャッシュ期限切れ
    }
    return decoded['data'];
  }

  /// キャッシュを削除
  Future<void> clear(String key) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(key);
  }
}
