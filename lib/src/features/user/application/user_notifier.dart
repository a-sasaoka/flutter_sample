import 'package:flutter_sample/src/features/user/data/user_repository.dart';
import 'package:flutter_sample/src/features/user/domain/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_notifier.g.dart';

/// UserNotifier
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<List<UserModel>> build() async {
    // 初回表示時は通常通り（キャッシュがあればキャッシュを使う）
    return ref.read(userRepositoryProvider).fetchUsers();
  }

  /// 引っ張って更新などで強制的にAPIから再取得する
  Future<void> refresh() async {
    // 状態を Loading にする（くるくるを表示したい場合）
    state = const AsyncValue.loading();

    // 非同期で状態を上書きする（forceRefresh: true）
    state = await AsyncValue.guard(() async {
      return ref.read(userRepositoryProvider).fetchUsers(forceRefresh: true);
    });
  }
}
