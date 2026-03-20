import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/chat/application/chat_notifier.dart';
import 'package:flutter_sample/src/features/chat/data/chat_repository.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// チャット画面
class ChatScreen extends HookConsumerWidget {
  /// コンストラクタ
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatProvider);
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
                return switch (msg) {
                  ChatMessageLoading() => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  ChatMessageUser(:final text) => _buildBubble(
                    text: text,
                    isUser: true,
                    color: Colors.blueAccent,
                    textColor: Colors.white,
                    context: context,
                  ),
                  ChatMessageAi(:final text) => _buildBubble(
                    text: text,
                    isUser: false,
                    color: Colors.grey[300]!,
                    textColor: Colors.black87,
                    context: context,
                  ),
                  ChatMessageError(:final error) => _buildBubble(
                    text: error is ChatEmptyResponseException
                        ? l10n.chatEmptyMessage
                        : l10n.chatError(error.toString()),
                    isUser: false,
                    color: Colors.red[100]!,
                    textColor: Colors.red[900]!,
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
                      decoration: InputDecoration(
                        hintText: l10n.chatHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () async {
                        // 1. 送信するテキストを変数に保持
                        final text = textController.text;

                        // 2. 即座に入力フォームをクリア（ユーザーを待たせない）
                        textController.clear();

                        // 3. AIにメッセージを送信
                        // AI回答をリアルタイムで表示する場合はsendMessageStreamを使う
                        // AI回答を全て取得して表示する場合はsendMessageを使う
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
    required String text,
    required bool isUser,
    required Color color,
    required Color textColor,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
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
                  selectable: true, // 長押しでテキストをコピーできるようにする
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    code: TextStyle(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
