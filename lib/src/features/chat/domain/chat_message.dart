import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';

/// チャットメッセージのクラス
@freezed
sealed class ChatMessage with _$ChatMessage {
  const ChatMessage._(); // coverage:ignore-line

  /// ユーザーの送信メッセージ
  const factory ChatMessage.user({
    required String id,
    required String text,
    required DateTime createdAt,
  }) = ChatMessageUser;

  /// AIからの返答メッセージ
  const factory ChatMessage.ai({
    required String id,
    required String text,
    required DateTime createdAt,
  }) = ChatMessageAi;

  /// AIの返答待ち（ローディング）
  const factory ChatMessage.loading({
    required String id,
    required DateTime createdAt,
  }) = ChatMessageLoading;

  /// エラー発生時のメッセージ
  const factory ChatMessage.error({
    required String id,
    required Object error,
    required DateTime createdAt,
  }) = ChatMessageError;

  /// ユーザーのメッセージかどうかを判定
  bool get isUser => this is ChatMessageUser;

  /// AIのメッセージかどうかを判定
  bool get isAi => this is ChatMessageAi;

  /// 画面に表示すべきテキストがあれば返す（なければnull）
  String? get displayText {
    return switch (this) {
      ChatMessageUser(:final text) => text,
      ChatMessageAi(:final text) => text,
      _ => null,
    };
  }
}
