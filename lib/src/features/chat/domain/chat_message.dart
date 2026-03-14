import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';

/// チャットメッセージのクラス
@freezed
sealed class ChatMessage with _$ChatMessage {
  /// ユーザーの送信メッセージ
  const factory ChatMessage.user({required String text}) = ChatMessageUser;

  /// AIからの返答メッセージ
  const factory ChatMessage.ai({required String text}) = ChatMessageAi;

  /// AIの返答待ち（ローディング）
  const factory ChatMessage.loading() = ChatMessageLoading;

  /// エラー発生時のメッセージ
  const factory ChatMessage.error({required Object error}) = ChatMessageError;
}
