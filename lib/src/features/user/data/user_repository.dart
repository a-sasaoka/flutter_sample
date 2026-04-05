// APIクライアント経由でユーザー一覧を取得

import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/storage/cache_manager.dart';
import 'package:flutter_sample/src/features/user/domain/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_repository.g.dart';

/// UserRepositoryを提供するプロバイダ
@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository(
    api: ref.watch(apiClientProvider),
    cache: ref.watch(cacheManagerProvider),
  );
}

/// UserRepository本体
class UserRepository {
  /// コンストラクタ
  const UserRepository({
    required this.api,
    required this.cache,
  });

  /// APIクライアント
  final ApiClient api;

  /// キャッシュマネージャー
  final CacheManager cache;

  /// ユーザー一覧を取得
  /// [forceRefresh] true の場合はキャッシュを無視してAPIから再取得する
  Future<List<UserModel>> fetchUsers({bool forceRefresh = false}) async {
    const cacheKey = 'users';

    // 強制更新でない場合のみ、キャッシュを確認する
    if (!forceRefresh) {
      final cachedData = await cache.get(cacheKey);
      if (cachedData != null) {
        // キャッシュから読み込む
        return (cachedData as List)
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
      }
    }

    // APIから取得
    final response = await api.get<List<dynamic>>('/users');
    final users = response.data!
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    // キャッシュに保存（上書き）
    await cache.save(cacheKey, response.data);

    return users;
  }
}
