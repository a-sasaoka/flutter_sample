import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_sort_order.dart';
import 'package:flutter_sample/src/features/memos/presentation/memo_list_shimmer.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// メモ画面
class MemoScreen extends ConsumerWidget {
  /// コンストラクタ
  const MemoScreen({super.key}); // coverage:ignore-line

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.memoTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => ref.read(memoProvider.notifier).sync(),
              tooltip: l10n.memoSyncing,
            ),
          ],
        ),
        body: Column(
          children: [
            // 検索窓とソートボタンを上部に配置します
            const _MemoSearchAndSortBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(memoProvider.future),
                child: const _MemoListView(),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddMemoDialog(context, ref),
          icon: const Icon(Icons.add),
          label: Text(l10n.memoAdd),
        ),
      ),
    );
  }

  Future<void> _showAddMemoDialog(BuildContext context, WidgetRef ref) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => HookBuilder(
        builder: (context) {
          final l10n = context.l10n;
          final titleController = useTextEditingController();
          final contentController = useTextEditingController();
          final isLoading = useState(false);

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.memoAdd,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: l10n.memoInputTitleHint,
                      prefixIcon: const Icon(Icons.title),
                      border: const OutlineInputBorder(),
                    ),
                    autofocus: true,
                    enabled: !isLoading.value,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(
                      labelText: l10n.memoInputContentHint,
                      prefixIcon: const Icon(Icons.notes),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    enabled: !isLoading.value,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: isLoading.value
                        ? null
                        : () async {
                            final title = titleController.text;
                            if (title.isNotEmpty) {
                              isLoading.value = true;
                              try {
                                await ref
                                    .read(memoProvider.notifier)
                                    .addMemo(title, contentController.text);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              } finally {
                                if (context.mounted) {
                                  isLoading.value = false;
                                }
                              }
                            }
                          },
                    icon: isLoading.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(l10n.memoSave),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// メモ一覧の上部に表示する、検索窓と並び替え（ソート）ボタンのバー
class _MemoSearchAndSortBar extends HookConsumerWidget {
  const _MemoSearchAndSortBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // 検索窓に入力されている現在のキーワードを監視します
    final searchQuery = ref.watch(memoSearchQueryProvider);
    // 現在選ばれている並び替え順を監視します
    final sortOrder = ref.watch(memoSortOrderStateProvider);

    // 入力窓の文字を管理するためのコントローラ
    final controller = useTextEditingController(text: searchQuery);

    // 検索条件が他から空っぽにされた際などに、入力窓の文字もクリアします
    useEffect(() {
      if (searchQuery != controller.text) {
        controller.text = searchQuery;
      }
      return null;
    }, [searchQuery]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // 検索窓（文字を入れるとリアルタイムに検索が走るインクリメンタルサーチ）
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: l10n.memoSearchHint,
                prefixIcon: const Icon(Icons.search),
                // 文字が入力されている場合のみ、クリア用の「×」ボタンを表示します
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          ref
                              .read(memoSearchQueryProvider.notifier)
                              .setQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                ref.read(memoSearchQueryProvider.notifier).setQuery(value);
              },
            ),
          ),
          const SizedBox(width: 8),
          // 並び替えルールを選択するポップアップメニューボタン
          PopupMenuButton<MemoSortOrder>(
            initialValue: sortOrder,
            icon: const Icon(Icons.sort),
            onSelected: (order) {
              ref.read(memoSortOrderStateProvider.notifier).setSortOrder(order);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: MemoSortOrder.createdAtDesc,
                child: Text(l10n.memoSortCreatedAtDesc),
              ),
              PopupMenuItem(
                value: MemoSortOrder.createdAtAsc,
                child: Text(l10n.memoSortCreatedAtAsc),
              ),
              PopupMenuItem(
                value: MemoSortOrder.updatedAtDesc,
                child: Text(l10n.memoSortUpdatedAtDesc),
              ),
              PopupMenuItem(
                value: MemoSortOrder.updatedAtAsc,
                child: Text(l10n.memoSortUpdatedAtAsc),
              ),
              PopupMenuItem(
                value: MemoSortOrder.titleAsc,
                child: Text(l10n.memoSortTitleAsc),
              ),
              PopupMenuItem(
                value: MemoSortOrder.titleDesc,
                child: Text(l10n.memoSortTitleDesc),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// メモ一覧を表示するウィジェット
class _MemoListView extends ConsumerWidget {
  const _MemoListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final memosAsyncValue = ref.watch(memoProvider);

    return switch (memosAsyncValue) {
      AsyncData(value: final memos) when memos.isEmpty => ListView(
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.memoEmpty,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      AsyncData(value: final memos) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: memos.length,
        itemBuilder: (context, index) {
          final memo = memos[index];
          return _MemoCard(key: ValueKey(memo.id), memo: memo);
        },
      ),
      AsyncError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(l10n.errorUnknown),
          ],
        ),
      ),
      _ => const MemoListShimmer(),
    };
  }
}

class _MemoCard extends ConsumerWidget {
  const _MemoCard({required this.memo, super.key});
  final MemoModel memo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        title: Text(
          memo.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(memo.content),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  memo.isSynced ? Icons.cloud_done : Icons.cloud_off,
                  size: 14,
                  color: memo.isSynced
                      ? colorScheme.primary
                      : colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  memo.isSynced ? l10n.memoSynced : l10n.memoUnsynced,
                  style: TextStyle(
                    fontSize: 10,
                    color: memo.isSynced
                        ? colorScheme.primary
                        : colorScheme.error,
                  ),
                ),
                const Spacer(),
                Text(
                  '${memo.createdAt.month}/${memo.createdAt.day} ${memo.createdAt.hour.toString().padLeft(2, '0')}:${memo.createdAt.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: colorScheme.error),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.memoDeleteConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.close),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      l10n.delete,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await ref.read(memoProvider.notifier).deleteMemo(memo.id);
            }
          },
        ),
      ),
    );
  }
}
