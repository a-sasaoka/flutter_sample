import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/storage/cache_manager.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/user/domain/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'user_repository.g.dart';

/// UserRepositoryを提供するプロバイダ
@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository(
    api: ref.watch(apiClientProvider),
    cache: ref.watch(cacheManagerProvider),
    talker: ref.watch(loggerProvider),
    clock: ref.watch(clockProvider),
  );
}

/// UserRepository本体
class UserRepository {
  /// コンストラクタ
  const UserRepository({
    required this.api,
    required this.cache,
    required this.talker,
    required this.clock,
  });

  /// APIクライアント
  final ApiClient api;

  /// キャッシュマネージャー
  final CacheManager cache;

  /// ロガー
  final Talker talker;

  /// 現在日時取得関数
  final DateTime Function() clock;

  /// キャッシュのキー
  static const cacheKey = 'users';

  /// ユーザー一覧を取得
  /// [forceRefresh] true の場合はキャッシュを無視してAPIから再取得する
  Future<(List<UserModel>, DateTime)> fetchUsers({
    bool forceRefresh = false,
  }) async {
    // 強制更新でない場合のみ、キャッシュを確認する
    if (!forceRefresh) {
      final (cachedData, timestamp) = await cache.getWithTimestamp(cacheKey);
      if (cachedData case final List<dynamic> data) {
        // キャッシュから読み込む
        talker.debug('Loaded users from cache.');
        return (
          data
              .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
              .toList(growable: false),
          timestamp ?? clock(),
        );
      }
    }

    // APIから取得
    final response = await api.get<List<dynamic>>('/users');
    if (response.data case final List<dynamic> data) {
      final users = data
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);

      // キャッシュに保存（上書き）
      await cache.save(cacheKey, data);
      talker.debug('Fetched users from API and saved to cache.');

      return (users, clock());
    }

    return (<UserModel>[], clock());
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

    if (response.data case final Map<String, dynamic> data) {
      // キャッシュをクリア
      await cache.clear(cacheKey);
      talker.debug('Created user and cleared cache.');

      return UserModel.fromJson(data);
    }

    throw const AppException.dataParse(message: 'Failed to create user');
  }

  /// ユーザー名を更新する (PATCHのサンプル)
  Future<UserModel> updateUserName(int id, String newName) async {
    final response = await api.patch<Map<String, dynamic>>(
      '/users/$id',
      data: {'name': newName},
    );

    if (response.data case final Map<String, dynamic> data) {
      // キャッシュをクリア
      await cache.clear(cacheKey);
      talker.debug('Updated user name and cleared cache.');

      return UserModel.fromJson(data);
    }

    throw const AppException.dataParse(message: 'Failed to update user');
  }

  /// ユーザーを削除する (DELETEのサンプル)
  Future<void> deleteUser(int id) async {
    await api.delete<void>('/users/$id');

    // キャッシュをクリア
    await cache.clear(cacheKey);
    talker.debug('Deleted user and cleared cache.');
  }
}
