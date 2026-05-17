import 'dart:convert';

import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'cache_manager.g.dart';

/// キャッシュマネージャープロバイダー
@Riverpod(keepAlive: true)
CacheManager cacheManager(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CacheManager(
    prefs: prefs,
    getCurrentDateTime: ref.watch(clockProvider),
  );
}

/// キャッシュマネージャー
class CacheManager {
  /// コンストラクタ
  const CacheManager({
    required SharedPreferencesAsync prefs,
    required DateTime Function() getCurrentDateTime,
    Duration cacheDuration = const Duration(minutes: 10),
  }) : _prefs = prefs,
       _getCurrentDateTime = getCurrentDateTime,
       _cacheDuration = cacheDuration;

  final SharedPreferencesAsync _prefs;
  final DateTime Function() _getCurrentDateTime;
  final Duration _cacheDuration;

  static const _keyTimestamp = 'timestamp';
  static const _keyData = 'data';

  /// キャッシュを保存
  Future<void> save(String key, dynamic value) async {
    final data = {
      _keyTimestamp: _getCurrentDateTime().millisecondsSinceEpoch,
      _keyData: value,
    };
    await _prefs.setString(key, jsonEncode(data));
  }

  /// キャッシュを取得（期限切れならnull）
  Future<dynamic> get(String key) async {
    final (data, _) = await getWithTimestamp(key);
    return data;
  }

  /// キャッシュを削除
  Future<void> clear(String key) async {
    await _prefs.remove(key);
  }

  /// キャッシュデータと保存日時を同時に取得
  /// 期限切れやエラーの場合は (null, null) を返す
  Future<(dynamic data, DateTime? timestamp)> getWithTimestamp(
    String key,
  ) async {
    final raw = await _prefs.getString(key);
    if (raw == null) return (null, null);

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        decoded[_keyTimestamp] as int,
      );

      // 有効期限チェック
      if (_getCurrentDateTime().difference(timestamp) > _cacheDuration) {
        await _prefs.remove(key);
        return (null, null);
      }

      return (decoded[_keyData], timestamp);
    } on Object catch (_) {
      // JSONパースエラーや型の不一致などが起きた場合は、キャッシュが壊れているとみなして削除
      await _prefs.remove(key);
      return (null, null);
    }
  }
}
