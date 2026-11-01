import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/utils/date_time_extension.dart';
import 'package:flutter_sample/src/core/utils/debouncer.dart';
import 'package:flutter_sample/src/core/widgets/app_cached_image.dart';
import 'package:flutter_sample/src/core/widgets/empty_state_widget.dart';
import 'package:flutter_sample/src/core/widgets/highlighted_text.dart';
import 'package:flutter_sample/src/features/user/application/user_notifier.dart';
import 'package:flutter_sample/src/features/user/application/user_search_query.dart';
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
    ref.listen(filteredUsersProvider, (previous, next) {
      // すでにデータ（キャッシュ）がある場合は、エラーのスナックバーを出さないようにする
      if (next.hasValue) return;

      if (next case AsyncError(:final error) when !next.isLoading) {
        ErrorHandler.showSnackBar(context, error);
      }
    });

    final usersAsync = ref.watch(userProvider);
    final filteredUsersAsync = ref.watch(filteredUsersProvider);
    final searchQuery = ref.watch(userSearchQueryProvider);
    final isRetrying = useState(false);

    // リフレッシュ処理の共通化
    Future<void> onRefresh() => ref.read(userProvider.notifier).refresh();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.userListTitle),
              if (usersAsync.value case (_, final DateTime lastFetchedAt))
                Text(
                  l10n.userListLastFetched(lastFetchedAt.toFormattedString()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            const _UserSearchBar(),
            Expanded(
              child: switch (filteredUsersAsync) {
                // 💡 データがある場合 (エラーやローディング中でも、データがあれば表示)
                AsyncValue(value: (final value, _)?) when value.isNotEmpty =>
                  RefreshIndicator(
                    onRefresh: onRefresh,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: value.length,
                      itemBuilder: (context, index) {
                        final user = value[index];
                        return _UserCard(key: ValueKey(user.id), user: user);
                      },
                    ),
                  ),
                // 💡 データが空の場合
                AsyncValue(value: (final value, _)?) when value.isEmpty =>
                  RefreshIndicator(
                    onRefresh: onRefresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.15,
                        ),
                        if (searchQuery.trim().isNotEmpty)
                          EmptyStateWidget(
                            title: l10n.userSearchEmpty,
                            actionLabel: l10n.userClearFilter,
                            onAction: () {
                              ref
                                  .read(userSearchQueryProvider.notifier)
                                  .clear();
                            },
                          )
                        else
                          EmptyStateWidget(title: l10n.userListEmpty),
                      ],
                    ),
                  ),
                // 💡 エラー状態 (データがない場合)
                AsyncError() => RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.25,
                      ),
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
                              l10n.userListFetchError,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSearchBar extends HookConsumerWidget {
  const _UserSearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentQuery = ref.watch(userSearchQueryProvider);
    final controller = useTextEditingController(text: currentQuery);
    // 入力中の文字の有無に応じてクリアボタン（×）を即座に再描画するために購読
    useListenable(controller);
    final debouncer = useMemoized(Debouncer.new, const []);

    useEffect(() => debouncer.dispose, const []);

    // 外部からクエリが変更された場合に入力欄を同期し、保留中のデバウンスもキャンセル
    ref.listen<String>(userSearchQueryProvider, (previous, next) {
      if (controller.text != next) {
        controller.text = next;
      }
      if (next.isEmpty) {
        debouncer.cancel();
      }
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: l10n.userSearchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    debouncer.cancel();
                    ref.read(userSearchQueryProvider.notifier).clear();
                  },
                )
              : null,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (text) {
          debouncer.run(() {
            ref.read(userSearchQueryProvider.notifier).setQuery(text);
          });
        },
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({required this.user, super.key});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final searchQuery = ref.watch(userSearchQueryProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: AppCachedImage.circle(
          imageUrl: user.avatarUrl,
          size: 40,
          fallbackWidget: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
          ),
        ),
        title: HighlightedText(
          text: user.name,
          highlight: searchQuery,
          style: const TextStyle(fontWeight: FontWeight.bold),
          highlightStyle: TextStyle(
            fontWeight: FontWeight.bold,
            backgroundColor: colorScheme.primaryContainer,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _IconText(
              icon: Icons.email_outlined,
              text: user.email,
              highlight: searchQuery,
            ),
            const SizedBox(height: 4),
            _IconText(
              icon: Icons.location_on_outlined,
              text: user.address.city,
            ),
            const SizedBox(height: 4),
            _IconText(icon: Icons.public_outlined, text: user.website),
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
  const _IconText({required this.icon, required this.text, this.highlight});
  final IconData icon;
  final String text;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: highlight != null && highlight!.trim().isNotEmpty
              ? HighlightedText(
                  text: text,
                  highlight: highlight!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  highlightStyle: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(
                        backgroundColor: colorScheme.primaryContainer,
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                )
              : Text(
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
