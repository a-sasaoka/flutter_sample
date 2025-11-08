// lib/src/features/user/data/user_repository.dart
// APIクライアント経由でユーザー一覧を取得

import 'package:flutter_sample/src/data/datasource/api_client.dart';
import 'package:flutter_sample/src/features/user/date/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_repository.g.dart';

/// ユーザーリポジトリ
@riverpod
class UserRepository extends _$UserRepository {
  @override
  void build() {}

  /// ユーザー一覧を取得
  Future<List<UserModel>> fetchUsers() async {
    final api = ref.read(apiClientProvider);
    final response = await api.get<List<dynamic>>('/users');
    final users = response.data!
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return users;
  }
}
