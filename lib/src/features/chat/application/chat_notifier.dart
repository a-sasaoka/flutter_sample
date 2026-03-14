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
}
