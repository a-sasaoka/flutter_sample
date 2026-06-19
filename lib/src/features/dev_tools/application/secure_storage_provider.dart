import 'package:flutter_sample/src/core/storage/secure_storage_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_provider.g.dart';

/// SecureStorageのデータを非同期で監視・操作するNotifier
@riverpod
class SecureStorageItems extends _$SecureStorageItems {
  late final FlutterSecureStorage _storage;

  @override
  FutureOr<Map<String, String>> build() async {
    _storage = ref.watch(secureStorageProvider);
    return _storage.readAll();
  }

  /// 値を設定または更新する
  Future<void> set(String key, String value) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _storage.write(key: key, value: value);
      return _storage.readAll();
    });
  }

  /// 指定したキーを削除する
  Future<void> remove(String key) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _storage.delete(key: key);
      return _storage.readAll();
    });
  }

  /// すべてのデータを削除する
  Future<void> clear() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _storage.deleteAll();
      return <String, String>{};
    });
  }
}
