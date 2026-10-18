import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_stream_event.freezed.dart';

/// チャットAPIから受信するストリーミングイベント
///
/// テキストの断片（テキストチャンク）または、
/// AIモデルからのアプリ機能実行要求（FunctionCall）を表します。
@freezed
sealed class ChatStreamEvent with _$ChatStreamEvent {
  /// 通常のテキストチャンク
  const factory ChatStreamEvent.text(String text) = ChatStreamEventText;

  /// AIモデルからのアプリ機能実行要求
  const factory ChatStreamEvent.functionCall({
    required String name,
    required Map<String, Object?> args,
    String? id,
  }) = ChatStreamEventFunctionCall;
}

/// AIモデルへ返却するツール実行結果
typedef ChatFunctionResponse = ({
  String name,
  Map<String, Object?> response,
  String? id,
});
