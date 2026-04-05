import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/chat/application/chat_notifier.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// チャット画面
class ChatScreen extends HookConsumerWidget {
  /// コンストラクタ
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatProvider);

    final isGenerating = ref.watch(chatProvider.notifier).isGenerating;

    final textController = useTextEditingController();
    final scrollController = useScrollController();
    final l10n = AppLocalizations.of(context)!;

    // メッセージリスト（state）の変更を監視して、自動スクロールを実行する
    ref.listen(chatProvider, (previous, next) {
      // 画面の描画（レイアウト）が完了するのを一瞬待ってからスクロールさせる
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (scrollController.hasClients) {
          await scrollController.animateTo(
            // リストの一番下（最大スクロール位置）を指定
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), // アニメーションの秒数
            curve: Curves.easeOut,
          );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatTitle),
      ),
      body: Column(
        children: [
          // メッセージリスト表示部分
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                // Dart3のパターンマッチングでUIを出し分ける
                // sealedクラスなので、全パターン網羅しないとコンパイルエラーになり安全
                // 追加した id と createdAt を取り出してUIに適用する
                return switch (msg) {
                  ChatMessageLoading(:final id) => Padding(
                    key: Key(id), // Keyを設定してUIのチラつきを防止
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  ChatMessageUser(:final id, :final text, :final createdAt) =>
                    _buildBubble(
                      key: Key(id),
                      text: text,
                      isUser: true,
                      color: Colors.blueAccent,
                      textColor: Colors.white,
                      createdAt: createdAt,
                      context: context,
                    ),
                  ChatMessageAi(:final id, :final text, :final createdAt) =>
                    _buildBubble(
                      key: Key(id),
                      text: text,
                      isUser: false,
                      color: Colors.grey[300]!,
                      textColor: Theme.of(context).colorScheme.onSurface,
                      createdAt: createdAt,
                      context: context,
                    ),
                  ChatMessageError(:final id, :final error, :final createdAt) =>
                    _buildBubble(
                      key: Key(id),
                      text: error is ChatEmptyResponseException
                          ? l10n.chatEmptyMessage
                          : l10n.chatError(error.toString()),
                      isUser: false,
                      color: Colors.red[100]!,
                      textColor: Colors.red[900]!,
                      createdAt: createdAt,
                      context: context,
                    ),
                };
              },
            ),
          ),
          // 下部の入力フォーム
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      // 生成中は TextField への入力を無効化する
                      enabled: !isGenerating,
                      decoration: InputDecoration(
                        hintText: isGenerating ? l10n.thinking : l10n.chatHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      // Enterキー（完了）を押した時も送信できるようにする
                      onSubmitted: (text) async {
                        // 生成中は送信できないようにブロック
                        if (text.trim().isEmpty || isGenerating) return;
                        textController.clear();
                        await ref
                            .read(chatProvider.notifier)
                            .sendMessageStream(text);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: isGenerating
                        ? Colors.grey
                        : Colors.blueAccent,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      // 生成中は onPressed を null にして完全にボタンを無効化する
                      onPressed: isGenerating
                          ? null
                          : () async {
                              final text = textController.text;
                              if (text.trim().isEmpty) return;

                              textController.clear();

                              await ref
                                  .read(chatProvider.notifier)
                                  .sendMessageStream(text);
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 共通の吹き出しUIウィジェット
  Widget _buildBubble({
    required Key key,
    required String text,
    required bool isUser,
    required Color color,
    required Color textColor,
    required DateTime createdAt,
    required BuildContext context,
  }) {
    final timeString =
        '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';

    final timeWidget = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        timeString,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 10,
          color: Colors.grey[600],
        ),
      ),
    );

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: isUser
          ? Text(
              text,
              style: TextStyle(color: textColor),
            )
          : MarkdownBody(
              data: text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: textColor),
                code: TextStyle(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  fontFamily: 'monospace',
                ),
              ),
            ),
    );

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isUser) timeWidget,
          if (isUser) const SizedBox(width: 8),

          bubble,

          if (!isUser) const SizedBox(width: 8),
          if (!isUser) timeWidget,
        ],
      ),
    );
  }
}
