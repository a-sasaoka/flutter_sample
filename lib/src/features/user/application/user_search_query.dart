import 'package:flutter_sample/src/features/user/application/user_notifier.dart';
import 'package:flutter_sample/src/features/user/domain/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_search_query.g.dart';

/// ユーザー検索クエリ（キーワード）を管理するプロバイダー
@riverpod
class UserSearchQuery extends _$UserSearchQuery {
  @override
  String build() => '';

  /// 検索クエリを更新します
  void setQuery(String query) {
    if (state != query) {
      state = query;
    }
  }

  /// 検索クエリをクリア（空文字にリセット）します
  void clear() {
    state = '';
  }
}

/// 検索クエリによって絞り込まれたユーザー一覧を提供するプロバイダー
@riverpod
AsyncValue<(List<UserModel>, DateTime?)> filteredUsers(Ref ref) {
  final usersAsync = ref.watch(userProvider);
  final query = ref.watch(userSearchQueryProvider).trim().toLowerCase();

  (List<UserModel>, DateTime?) filterData((List<UserModel>, DateTime?) data) {
    final (users, lastFetchedAt) = data;
    if (query.isEmpty) {
      return (users, lastFetchedAt);
    }
    final filtered = users.where((user) {
      final matchesName = user.name.toLowerCase().contains(query);
      final matchesEmail = user.email.toLowerCase().contains(query);
      return matchesName || matchesEmail;
    }).toList();
    return (filtered, lastFetchedAt);
  }

  if (usersAsync.hasValue) {
    return AsyncData(filterData(usersAsync.requireValue));
  }
  if (usersAsync.hasError) {
    return AsyncError(usersAsync.error!, usersAsync.stackTrace!);
  }
  return const AsyncLoading();
}
