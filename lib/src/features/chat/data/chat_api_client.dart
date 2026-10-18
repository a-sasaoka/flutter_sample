import 'dart:typed_data';

import 'package:flutter_sample/src/features/chat/domain/chat_stream_event.dart';

/// チャットAPIクライアントのインターフェース
abstract class ChatApiClient {
  /// メッセージを送信するメソッド
  Future<String?> sendMessage(String prompt, {Uint8List? imageBytes});

  /// メッセージを送信するストリームメソッド（テキストチャンクおよびツール呼び出し要求をストリーミング配信）
  Stream<ChatStreamEvent> sendMessageStream(
    String prompt, {
    Uint8List? imageBytes,
  });

  /// ツール実行結果をAIに送信し、後続の返答ストリームを受信するメソッド
  Stream<ChatStreamEvent> sendFunctionResponseStream({
    required String name,
    required Map<String, Object?> response,
    String? id,
  });
}

/// AIからの返答が空だった時の例外クラス
class ChatEmptyResponseException implements Exception {}

/// サポートされていない画像形式だった場合の例外クラス
class ChatUnsupportedImageFormatException implements Exception {}
