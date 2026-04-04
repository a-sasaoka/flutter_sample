import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';
import 'package:flutter_sample/src/features/chat/data/chat_provider.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_notifier.g.dart';

/// チャットのやり取りを管理するプロバイダー
@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  List<ChatMessage> build() {
    // 画面（Notifier）が生きている間は、Repositoryも監視（watch）して破棄させない
    ref.watch(chatRepositoryProvider);
    return [];
  }

  /// メッセージを送信するメソッド
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _addMessageAndLoading(text);

    try {
      final repository = ref.read(chatRepositoryProvider);
      final promptWithTime = _buildPromptWithTime(text);
      final responseText = await repository.sendMessage(promptWithTime);

      _replaceLastMessage(ChatMessage.ai(text: responseText));
    } on Exception catch (e) {
      _replaceLastMessage(ChatMessage.error(error: e));
    }
  }

  /// メッセージを送信するメソッド（Stream版）
  Future<void> sendMessageStream(String text) async {
    if (text.trim().isEmpty) return;

    _addMessageAndLoading(text);

    try {
      final repository = ref.read(chatRepositoryProvider);
      final promptWithTime = _buildPromptWithTime(text);
      final stream = repository.sendMessageStream(promptWithTime);

      var isFirstChunk = true;

      await for (final chunk in stream) {
        if (isFirstChunk) {
          // 最初の1文字目でローディングをAIメッセージに差し替え
          _replaceLastMessage(ChatMessage.ai(text: chunk));
          isFirstChunk = false;
        } else {
          // 2回目以降は既存のテキストに継ぎ足し
          final lastMessage = state.last;
          if (lastMessage is ChatMessageAi) {
            _replaceLastMessage(
              ChatMessage.ai(text: lastMessage.text + chunk),
            );
          }
        }
      }

      if (isFirstChunk) {
        throw ChatEmptyResponseException(); // 空のままStreamが終わった場合
      }
    } on Exception catch (e) {
      _replaceLastMessage(ChatMessage.error(error: e));
    }
  }

  /// ユーザーメッセージとローディング状態をセットで追加する
  void _addMessageAndLoading(String text) {
    state = [
      ...state,
      ChatMessage.user(text: text),
      const ChatMessage.loading(),
    ];
  }

  /// 状態リストの「最後の要素」を新しいメッセージに差し替える
  void _replaceLastMessage(ChatMessage newMessage) {
    if (state.isEmpty) return;
    state = [
      ...state.sublist(0, state.length - 1),
      newMessage,
    ];
  }

  /// AIに送るプロンプトにシステム日時を付加する
  String _buildPromptWithTime(String originalText) {
    final now = ref.read(currentDateTimeProvider);
    return '（※システム情報: 現在時刻は ${now.year}年${now.month}月${now.day}日'
        ' ${now.hour}時${now.minute}分 です）\n$originalText';
  }
}
