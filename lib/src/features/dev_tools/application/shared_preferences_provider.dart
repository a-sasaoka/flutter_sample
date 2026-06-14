import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_preferences_provider.g.dart';

/// SharedPreferencesのデータを非同期で監視・操作するNotifier
@riverpod
class SharedPreferencesItems extends _$SharedPreferencesItems {
  late final SharedPreferencesAsync _prefs;

  @override
  FutureOr<Map<String, Object?>> build() async {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _fetchCurrentMap();
  }

  /// 値を設定または更新する
  Future<void> set(String key, Object value) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is bool) {
        await _prefs.setBool(key, value);
      } else {
        throw ArgumentError('Unsupported value type: ${value.runtimeType}');
      }
      return _fetchCurrentMap();
    });
  }

  /// 指定したキーを削除する
  Future<void> remove(String key) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _prefs.remove(key);
      return _fetchCurrentMap();
    });
  }

  /// すべてのデータを削除する
  Future<void> clear() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _prefs.clear();
      return <String, Object?>{};
    });
  }

  /// 現在のSharedPreferencesのマップを取得する
  Future<Map<String, Object?>> _fetchCurrentMap() async {
    return _prefs.getAll();
  }
}
