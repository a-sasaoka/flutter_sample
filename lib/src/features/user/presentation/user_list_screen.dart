// ユーザー一覧を表示する画面

import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/features/user/application/user_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// ユーザー一覧画面
class UserListScreen extends ConsumerWidget {
  /// コンストラクタ
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // エラー時のスナックバー表示は `ref.listen` で監視する
    // これにより、ビルド中の副作用（何度もスナックバーが出る等）を完全に防げます
    ref.listen(userProvider, (previous, next) {
      if (!next.isLoading && next.hasError) {
        ErrorHandler.showSnackBar(context, next.error!);
      }
    });

    final usersAsync = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userListTitle)),
      body: usersAsync.when(
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.read(userProvider.notifier).refresh(),
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final user = list[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(user.name),
                subtitle: Text('${user.email}\n${user.address.city}'),
                isThreeLine: true,
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(l10n.errorUnknown),
        ),
      ),
    );
  }
}
