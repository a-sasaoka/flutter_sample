import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_state.freezed.dart';

/// チャットの状態を保持するクラス
@freezed
sealed class ChatState with _$ChatState {
  /// コンストラクタ
  const factory ChatState({
    @Default([]) List<ChatMessage> messages,
    @Default(false) bool isGenerating,
  }) = _ChatState;
}
