import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/user/application/user_notifier.dart';
import 'package:flutter_sample/src/features/user/domain/user_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// ユーザー一覧画面
class UserListScreen extends HookConsumerWidget {
  /// コンストラクタ
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // エラー時のスナックバー表示は `ref.listen` で監視する
    ref.listen(userProvider, (previous, next) {
      if (next case AsyncError(:final error) when !next.isLoading) {
        ErrorHandler.showSnackBar(context, error);
      }
    });

    final usersAsync = ref.watch(userProvider);
    final isRetrying = useState(false);

    // リフレッシュ処理の共通化
    Future<void> onRefresh() => ref.read(userProvider.notifier).refresh();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userListTitle)),
      body: switch (usersAsync) {
        // 💡 データが空の場合
        AsyncData(value: final list) when list.isEmpty => RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
              Center(
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
              ),
            ],
          ),
        ),
        // 💡 データがある場合
        AsyncData(value: final list) => RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final user = list[index];
              return _UserCard(key: ValueKey(user.id), user: user);
            },
          ),
        ),
        // 💡 エラー状態
        AsyncError() => RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
              Center(
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: isRetrying.value
                          ? null
                          : () async {
                              isRetrying.value = true;
                              try {
                                await onRefresh();
                              } finally {
                                if (context.mounted) {
                                  isRetrying.value = false;
                                }
                              }
                            },
                      icon: isRetrying.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.emailVerificationWaiting,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 💡 ローディング状態
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, super.key});
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
