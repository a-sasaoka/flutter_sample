import 'package:flutter_sample/src/features/chat/data/chat_repository.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_notifier.g.dart';

/// チャットのやり取りを管理するプロバイダー
@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  List<ChatMessage> build() {
    return [];
  }

  /// メッセージを送信するメソッド
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // ユーザーメッセージとローディング状態をまとめて追加
    state = [
      ...state,
      ChatMessage.user(text: text),
      const ChatMessage.loading(),
    ];

    try {
      final repository = ref.read(chatRepositoryProvider);
      final responseText = await repository.sendMessage(text);

      // 最後の要素（loading）をAIの返答に差し替える
      state = [
        ...state.sublist(0, state.length - 1),
        ChatMessage.ai(text: responseText),
      ];
    } on Exception catch (e) {
      // エラー時も同様にローディングをエラー表示に差し替える
      state = [
        ...state.sublist(0, state.length - 1),
        ChatMessage.error(error: e),
      ];
    }
  }

  /// メッセージを送信するメソッド（Stream版）
  Future<void> sendMessageStream(String text) async {
    if (text.trim().isEmpty) return;

    // ユーザーメッセージとローディング状態をまとめて追加
    state = [
      ...state,
      ChatMessage.user(text: text),
      const ChatMessage.loading(),
    ];

    try {
      final repository = ref.read(chatRepositoryProvider);

      // sendMessageStream を呼び出して、Streamを受け取る
      final stream = repository.sendMessageStream(text);

      // 最初の文字が届いたかどうかを判定するフラグ
      var isFirstChunk = true;

      // streamから文字のchunkが届くたびに、このループが回る
      await for (final chunk in stream) {
        if (isFirstChunk) {
          // 【最初の1文字目が届いた時】
          // ローディングを消して、最初の文字が入ったAIメッセージに差し替える
          state = [
            ...state.sublist(0, state.length - 1),
            ChatMessage.ai(text: chunk),
          ];
          isFirstChunk = false;
        } else {
          // 【2回目以降の文字が届いた時】
          // 今画面に出ている最後のAIメッセージの末尾に、新しい文字を「継ぎ足す」
          final lastMessage = state.last;
          if (lastMessage is ChatMessageAi) {
            state = [
              ...state.sublist(0, state.length - 1),
              ChatMessage.ai(text: lastMessage.text + chunk),
            ];
          }
        }
      }

      // 結果的に空っぽだったらエラー扱いにする
      if (isFirstChunk) {
        throw ChatEmptyResponseException();
      }
    } on Exception catch (e) {
      // エラーが発生した場合は、最後のメッセージ（ローディングまたは途中のAI文）をエラー表示に差し替える
      state = [
        ...state.sublist(0, state.length - 1),
        ChatMessage.error(error: e),
      ];
    }
  }
}
