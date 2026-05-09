import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// メモ画面
/// 自身は状態を持たず、レイアウトの枠組みだけを定義します。
class MemoScreen extends StatelessWidget {
  /// コンストラクタ
  const MemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.memoTitle)),
      // メモ一覧を表示するエリア
      body: const _MemoListView(),
      // 入力と追加を行うエリア
      bottomNavigationBar: const _MemoInputArea(),
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
          // メモが一つもない場合の表示
          return Center(child: Text(l10n.memoEmpty));
        }
        return ListView.builder(
          itemCount: memos.length,
          itemBuilder: (context, index) {
            final memo = memos[index];
            return ListTile(
              key: ValueKey(memo.id),
              title: Text(memo.title),
              subtitle: Text(memo.content),
              trailing: Text('${memo.createdAt.month}/${memo.createdAt.day}'),
            );
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

/// メモ入力エリア
class _MemoInputArea extends HookConsumerWidget {
  const _MemoInputArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // 入力管理に必要なコントローラー類を、このウィジェット内だけで管理します
    final titleController = useTextEditingController();
    final contentController = useTextEditingController();
    final isAdding = useState(false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: titleController,
                enabled: !isAdding.value,
                decoration: InputDecoration(
                  hintText: l10n.memoInputTitleHint,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: contentController,
                enabled: !isAdding.value,
                decoration: InputDecoration(
                  hintText: l10n.memoInputContentHint,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: isAdding.value
                  ? null
                  : () async {
                      final title = titleController.text;
                      if (title.isNotEmpty) {
                        isAdding.value = true;
                        try {
                          await ref
                              .read(memoProvider.notifier)
                              .addMemo(
                                title,
                                contentController.text,
                              );
                          titleController.clear();
                          contentController.clear();
                        } finally {
                          // ウィジェットが破棄されていないか確認してから状態を更新
                          if (context.mounted) {
                            isAdding.value = false;
                          }
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
