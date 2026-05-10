import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/features/user/application/user_notifier.dart';
import 'package:flutter_sample/src/features/user/domain/user_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// ユーザー一覧画面
class UserListScreen extends ConsumerWidget {
  /// コンストラクタ
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // エラー時のスナックバー表示は `ref.listen` で監視する
    ref.listen(userProvider, (previous, next) {
      if (next case AsyncError(:final error) when !next.isLoading) {
        ErrorHandler.showSnackBar(context, error);
      }
    });

    final usersAsync = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userListTitle)),
      body: usersAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.userListEmpty,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(userProvider.notifier).refresh(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final user = list[index];
                return _UserCard(user: user);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.errorUnknown,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.read(userProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _IconText(
              icon: Icons.email_outlined,
              text: user.email,
            ),
            const SizedBox(height: 4),
            _IconText(
              icon: Icons.location_on_outlined,
              text: user.address.city,
            ),
            const SizedBox(height: 4),
            _IconText(
              icon: Icons.public_outlined,
              text: user.website,
            ),
          ],
        ),
        onTap: () {
          // 詳細画面などがあればここに遷移
        },
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
