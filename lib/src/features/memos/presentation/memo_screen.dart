import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// メモ画面
class MemoScreen extends ConsumerWidget {
  /// コンストラクタ
  const MemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
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
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(memoProvider.future),
        child: const _MemoListView(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemoDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.memoAdd),
      ),
    );
  }

  Future<void> _showAddMemoDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
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
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final title = titleController.text;
                if (title.isNotEmpty) {
                  await ref
                      .read(memoProvider.notifier)
                      .addMemo(title, contentController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: Text(l10n.memoSave),
            ),
          ],
        ),
      ),
    );
  }
}

/// メモ一覧を表示するウィジェット
class _MemoListView extends ConsumerWidget {
  const _MemoListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final memosAsyncValue = ref.watch(memoProvider);

    return memosAsyncValue.when(
      data: (memos) {
        if (memos.isEmpty) {
          return ListView(
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
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: memos.length,
          itemBuilder: (context, index) {
            final memo = memos[index];
            return _MemoCard(memo: memo);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(l10n.errorUnknown),
      ),
    );
  }
}

class _MemoCard extends ConsumerWidget {
  const _MemoCard({required this.memo});
  final MemoModel memo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
                      l10n.logout, // "削除" がないので既存キー流用するか追加
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
