// lib/src/features/user/application/user_notifier.dart
// 状態管理（ロード中・成功・エラー）

import 'package:flutter_sample/src/features/user/date/user_model.dart';
import 'package:flutter_sample/src/features/user/date/user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_notifier.g.dart';

/// UserNotifier
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<List<UserModel>> build() async {
    return ref.read(userRepositoryProvider.notifier).fetchUsers();
  }

  /// ユーザー一覧をリフレッシュ
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(userRepositoryProvider.notifier).fetchUsers();
    });
  }
}
