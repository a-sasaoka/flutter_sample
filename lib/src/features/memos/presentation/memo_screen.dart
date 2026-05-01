import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// メモを一覧表示し、新しいメモを追加できる画面
class MemoScreen extends HookConsumerWidget {
  /// コンストラクタ
  const MemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final memosAsyncValue = ref.watch(memoProvider);

    final titleController = useTextEditingController();
    final contentController = useTextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.memoTitle)),

      body: memosAsyncValue.when(
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
      ),

      // 画面の一番下に表示される、入力欄と追加ボタンのエリア
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: l10n.memoInputTitleHint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    hintText: l10n.memoInputContentHint,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    await ref
                        .read(memoProvider.notifier)
                        .addMemo(
                          titleController.text,
                          contentController.text,
                        );
                    titleController.clear();
                    contentController.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
