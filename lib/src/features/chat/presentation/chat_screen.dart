import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/features/chat/application/chat_notifier.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// チャット画面
/// 画面全体のレイアウトを定義しますが、自身は状態を監視しないため、
/// メッセージの更新による不要なリビルドを防ぎます。
class ChatScreen extends ConsumerWidget {
  /// コンストラクタ
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.chartClearAll),
                  content: Text(l10n.chartClearConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.close),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        l10n.chartClearAll,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                ref.read(chatProvider.notifier).clearHistory();
              }
            },
            tooltip: l10n.chartClearAll,
          ),
        ],
      ),
      body: const Column(
        children: [
          // メッセージリスト部分
          Expanded(child: _ChatListView()),
          // 下部の入力フォーム
          _ChatInputArea(),
        ],
      ),
    );
  }
}

/// メッセージリストを表示するウィジェット
class _ChatListView extends HookConsumerWidget {
  const _ChatListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 翻訳データを変数に入れておきます。リストの中で何度も計算しなくて済むようになり、動作が軽くなります。
    final l10n = context.l10n;

    // メッセージのリスト「だけ」を監視する
    final messages = ref.watch(chatProvider.select((s) => s.messages));
    final scrollController = useScrollController();

    // メッセージの更新（新しい発言や、AIが文字を書いている最中）に合わせて、スクロール位置を調整します。
    ref.listen(chatProvider.select((s) => s.messages), (previous, next) {
      // 画面の描画（レイアウト）が完了するのを一瞬待ってからスクロールさせる
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          // メッセージの「数」が変わった（新規発言やローディング開始）時はアニメーション
          if (previous?.length != next.length) {
            unawaited(
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
            );
          } else {
            // メッセージの「中身」が更新されている（AIがストリーミング中）時は、
            // アニメーションなしで即座に末尾へ移動（jumpTo）して、最新の文字を表示し続ける
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        }
      });
    });

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        // 各メッセージを専用のクラスとして描画します。
        // Flutterが「描き直す必要がない場所」を賢く判断できるようになり、パフォーマンスが向上します。
        return _ChatBubble(
          key: ValueKey(msg.id),
          message: msg,
          l10n: l10n,
        );
      },
    );
  }
}

/// 1つのメッセージ吹き出しを表示するウィジェット
class _ChatBubble extends StatelessWidget {
  /// コンストラクタ
  const _ChatBubble({
    required this.message,
    required this.l10n,
    super.key,
  });

  /// 表示するメッセージ
  final ChatMessage message;

  /// ローカライズ
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Dart3のパターンマッチングでUIを出し分ける
    return switch (message) {
      ChatMessageLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: CircularProgressIndicator(),
        ),
      ),
      ChatMessageUser(:final text, :final createdAt) => _BubbleLayout(
        text: text,
        isUser: true,
        color: Theme.of(context).colorScheme.primaryContainer,
        textColor: Theme.of(context).colorScheme.onPrimaryContainer,
        createdAt: createdAt,
      ),
      ChatMessageAi(:final text, :final createdAt) => _BubbleLayout(
        text: text,
        isUser: false,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        textColor: Theme.of(context).colorScheme.onSurface,
        createdAt: createdAt,
      ),
      ChatMessageError(:final error, :final createdAt) => _BubbleLayout(
        text: error is ChatEmptyResponseException
            ? l10n.chatEmptyMessage
            : l10n.chatError(error.toString()),
        isUser: false,
        color: Theme.of(context).colorScheme.errorContainer,
        textColor: Theme.of(context).colorScheme.onErrorContainer,
        createdAt: createdAt,
      ),
    };
  }
}

/// 吹き出しの共通レイアウト
class _BubbleLayout extends StatelessWidget {
  /// コンストラクタ
  const _BubbleLayout({
    required this.text,
    required this.isUser,
    required this.color,
    required this.textColor,
    required this.createdAt,
  });

  /// 表示するテキスト
  final String text;

  /// ユーザーのメッセージかどうか
  final bool isUser;

  /// 吹き出しの背景色
  final Color color;

  /// テキストの色
  final Color textColor;

  /// 作成日時
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isUser) timeWidget,
          if (isUser) const SizedBox(width: 8),
          _BubbleContainer(
            text: text,
            color: color,
            textColor: textColor,
            isUser: isUser,
          ),
          if (!isUser) const SizedBox(width: 8),
          if (!isUser) timeWidget,
        ],
      ),
    );
  }
}

/// 吹き出しのコンテナ（文字装飾を含む）
class _BubbleContainer extends StatelessWidget {
  /// コンストラクタ
  const _BubbleContainer({
    required this.text,
    required this.color,
    required this.textColor,
    required this.isUser,
  });

  /// 表示するテキスト
  final String text;

  /// 背景色
  final Color color;

  /// テキスト色
  final Color textColor;

  /// ユーザーメッセージかどうか
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Container(
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
  }
}

/// チャット入力エリア
class _ChatInputArea extends HookConsumerWidget {
  const _ChatInputArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 生成中かどうかのフラグ「だけ」を監視する
    final isGenerating = ref.watch(chatProvider.select((s) => s.isGenerating));
    // オンライン状態を監視
    final isOnline = ref.watch(isOnlineProvider);

    final textController = useTextEditingController();
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
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
                onSubmitted: (text) =>
                    _onSend(ref, textController, isGenerating, isOnline),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: isGenerating || !isOnline
                  ? Theme.of(context).colorScheme.outline
                  : Theme.of(context).colorScheme.primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: isGenerating || !isOnline
                    ? null
                    : () =>
                          _onSend(ref, textController, isGenerating, isOnline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSend(
    WidgetRef ref,
    TextEditingController controller,
    bool isGenerating,
    bool isOnline,
  ) async {
    final text = controller.text;
    if (text.trim().isEmpty || isGenerating || !isOnline) return;

    controller.clear();

    await ref.read(chatProvider.notifier).sendMessageStream(text);
  }
}
