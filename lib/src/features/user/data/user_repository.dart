import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
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

  /// キャッシュのキー
  static const cacheKey = 'users';

  /// ユーザー一覧を取得
  /// [forceRefresh] true の場合はキャッシュを無視してAPIから再取得する
  Future<List<UserModel>> fetchUsers({bool forceRefresh = false}) async {
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
    final data = response.data;
    if (data == null) {
      return [];
    }
    final users = data
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    // キャッシュに保存（上書き）
    await cache.save(cacheKey, response.data);

    return users;
  }

  /// ユーザーを新規作成する (POSTのサンプル)
  Future<UserModel> createUser(String name, String email) async {
    final response = await api.post<Map<String, dynamic>>(
      '/users',
      data: {
        'name': name,
        'email': email,
        'phone': '000-0000-0000',
        'website': 'example.com',
        'address': {
          'city': '未設定',
          'street': '未設定',
          'suite': '未設定',
        },
      },
    );

    final data = response.data;
    if (data == null) {
      throw const AppException.dataParse(message: 'Failed to create user');
    }

    // キャッシュをクリア
    await cache.clear(cacheKey);

    return UserModel.fromJson(data);
  }

  /// ユーザー名を更新する (PATCHのサンプル)
  Future<UserModel> updateUserName(int id, String newName) async {
    final response = await api.patch<Map<String, dynamic>>(
      '/users/$id',
      data: {'name': newName},
    );

    final data = response.data;
    if (data == null) {
      throw const AppException.dataParse(message: 'Failed to update user');
    }

    // キャッシュをクリア
    await cache.clear(cacheKey);

    return UserModel.fromJson(data);
  }

  /// ユーザーを削除する (DELETEのサンプル)
  Future<void> deleteUser(int id) async {
    await api.delete<void>('/users/$id');

    // キャッシュをクリア
    await cache.clear(cacheKey);
  }
}
