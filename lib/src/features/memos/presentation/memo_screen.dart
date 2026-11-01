import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/services/app_lock_state_provider.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/utils/debouncer.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/widgets/empty_state_widget.dart';
import 'package:flutter_sample/src/core/widgets/highlighted_text.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_sort_order.dart';
import 'package:flutter_sample/src/features/memos/presentation/memo_list_shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// メモ画面
class MemoScreen extends HookConsumerWidget {
  /// コンストラクタ
  const MemoScreen({this.action, super.key});

  /// ウィジェット等から渡されるアクション（'create' など）
  final String? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // 📱 新規追加アクションが指定されている場合のみ、アプリロック解除を待機して入力シートを開く
    final isCreateAction = action == 'create';
    final isUnlocked = isCreateAction && ref.watch(isAppUnlockedProvider);

    useEffect(() {
      if (isCreateAction && isUnlocked) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.replace('/memos');
            unawaited(_showAddMemoDialog(context, ref));
          }
        });
      }
      return null;
    }, [isCreateAction, isUnlocked]);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.memoTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () async {
                unawaited(HapticFeedback.lightImpact());
                try {
                  await ref.read(memoProvider.notifier).sync();
                } on Exception catch (e, st) {
                  ref.read(loggerProvider).handle(e, st, '手動同期中にエラーが発生しました');
                  if (context.mounted) {
                    ErrorHandler.showSnackBar(context, e);
                  }
                } finally {
                  unawaited(HapticFeedback.mediumImpact());
                }
              },
              tooltip: l10n.memoSyncing,
            ),
          ],
        ),
        body: Column(
          children: [
            // 検索窓とソートボタンを上部に配置
            const _MemoSearchAndSortBar(),
            // カテゴリタグ・未同期の絞り込みチップを配置
            const _MemoFilterChipsBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(memoProvider.notifier).sync(),
                child: const _MemoListView(),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            unawaited(HapticFeedback.lightImpact());
            unawaited(_showAddMemoDialog(context, ref));
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.memoAdd),
        ),
      ),
    );
  }

  Future<void> _showAddMemoDialog(BuildContext context, WidgetRef ref) async {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => HookBuilder(
        builder: (context) {
          final l10n = context.l10n;
          final titleController = useTextEditingController();
          final contentController = useTextEditingController();
          final selectedCategory = useState<MemoCategory?>(null);
          final isLoading = useState(false);

          return GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.opaque,
            child: SingleChildScrollView(
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
                  const SizedBox(height: 16),
                  // カテゴリ選択用のチップ
                  Text(
                    l10n.memoCategorySelect,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: MemoCategory.values.map((cat) {
                      final isSelected = selectedCategory.value == cat;
                      return ChoiceChip(
                        avatar: Icon(cat.icon, size: 16),
                        label: Text(cat.label(l10n)),
                        selected: isSelected,
                        onSelected: (selected) {
                          unawaited(HapticFeedback.selectionClick());
                          selectedCategory.value = selected ? cat : null;
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: isLoading.value
                        ? null
                        : () async {
                            final title = titleController.text;
                            if (title.isNotEmpty) {
                              isLoading.value = true;
                              unawaited(HapticFeedback.lightImpact());
                              try {
                                await ref
                                    .read(memoProvider.notifier)
                                    .addMemo(
                                      title,
                                      contentController.text,
                                      category: selectedCategory.value,
                                    );
                                unawaited(HapticFeedback.mediumImpact());
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
    final filter = ref.watch(memoFilterProvider);

    // デバウンス用のタイマー管理インスタンス
    final debouncer = useMemoized(Debouncer.new);
    useEffect(() => debouncer.dispose, [debouncer]);

    // 入力窓の文字を管理するためのコントローラ
    final controller = useTextEditingController(text: filter.query);
    // 入力中の文字の有無に応じてクリアボタン（×）を即座に再描画するために購読
    useListenable(controller);

    // 外部から条件がクリアされた場合にコントローラも同期
    useEffect(() {
      if (filter.query != controller.text) {
        controller.text = filter.query;
      }
      return null;
    }, [filter.query]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // 検索窓（400msデバウンス検索）
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: l10n.memoSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          debouncer.cancel();
                          ref.read(memoFilterProvider.notifier).setQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                // 文字入力の手が400ms止まったタイミングで検索クエリを発火
                debouncer.run(() {
                  ref.read(memoFilterProvider.notifier).setQuery(value);
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // 並び替えルールを選択するポップアップメニューボタン
          PopupMenuButton<MemoSortOrder>(
            initialValue: filter.sortOrder,
            icon: const Icon(Icons.sort),
            onSelected: (order) {
              ref.read(memoFilterProvider.notifier).setSortOrder(order);
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

/// カテゴリタグおよび未同期フラグによる横スクロール絞り込みバー
class _MemoFilterChipsBar extends ConsumerWidget {
  const _MemoFilterChipsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(memoFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // 「すべて」チップ
          FilterChip(
            label: Text(l10n.memoCategoryAll),
            selected: filter.category == null && !filter.unsyncedOnly,
            onSelected: (_) {
              unawaited(HapticFeedback.selectionClick());
              ref.read(memoFilterProvider.notifier).resetFilter();
            },
          ),
          const SizedBox(width: 8),
          // 各カテゴリチップ
          ...MemoCategory.values.map((cat) {
            final isSelected = filter.category == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(cat.icon, size: 16),
                label: Text(cat.label(l10n)),
                selected: isSelected,
                onSelected: (_) {
                  unawaited(HapticFeedback.selectionClick());
                  ref.read(memoFilterProvider.notifier).toggleCategory(cat);
                },
              ),
            );
          }),
          // 「未同期のみ」チップ
          FilterChip(
            avatar: Icon(
              Icons.cloud_off,
              size: 16,
              color: filter.unsyncedOnly
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : null,
            ),
            label: Text(l10n.memoFilterUnsyncedOnly),
            selected: filter.unsyncedOnly,
            onSelected: (_) {
              unawaited(HapticFeedback.selectionClick());
              ref.read(memoFilterProvider.notifier).toggleUnsyncedOnly();
            },
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
    final filter = ref.watch(memoFilterProvider);

    return switch (memosAsyncValue) {
      AsyncData(value: final memos) when memos.isEmpty => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
          if (filter.hasActiveFilter)
            EmptyStateWidget(
              title: l10n.memoSearchEmpty,
              actionLabel: l10n.memoClearFilter,
              onAction: () {
                unawaited(HapticFeedback.lightImpact());
                ref.read(memoFilterProvider.notifier).resetFilter();
              },
            )
          else
            EmptyStateWidget(title: l10n.memoEmpty),
        ],
      ),
      AsyncData(value: final memos) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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
    final searchQuery = ref.watch(memoFilterProvider).query;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        title: Row(
          children: [
            Expanded(
              child: HighlightedText(
                text: memo.title,
                highlight: searchQuery,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (memo.category case final MemoCategory cat) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 12,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      cat.label(l10n),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            HighlightedText(
              text: memo.content,
              highlight: searchQuery,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: colorScheme.error),
          onPressed: () async {
            unawaited(HapticFeedback.mediumImpact());
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
                    onPressed: () {
                      unawaited(HapticFeedback.lightImpact());
                      Navigator.pop(context, true);
                    },
                    child: Text(
                      l10n.delete,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              unawaited(HapticFeedback.vibrate());
              await ref.read(memoProvider.notifier).deleteMemo(memo.id);
            }
          },
        ),
      ),
    );
  }
}
