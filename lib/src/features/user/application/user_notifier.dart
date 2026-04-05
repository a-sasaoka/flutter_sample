// 状態管理（ロード中・成功・エラー）

import 'package:flutter_sample/src/features/user/data/user_repository.dart';
import 'package:flutter_sample/src/features/user/domain/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_notifier.g.dart';

/// UserNotifier
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<List<UserModel>> build() async {
    final repository = ref.watch(userRepositoryProvider);
    return repository.fetchUsers();
  }
}
