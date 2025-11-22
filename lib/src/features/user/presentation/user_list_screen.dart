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
    final users = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.userListTitle)),
      body: users.when(
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
        error: (e, _) {
          // 画面を表示した後にスナックバーを表示する
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ErrorHandler.showSnackBar(context, e);
          });
          return Center(
            child: Text(AppLocalizations.of(context)!.errorUnknown),
          );
        },
      ),
    );
  }
}
