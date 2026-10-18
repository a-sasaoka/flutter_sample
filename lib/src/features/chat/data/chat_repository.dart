import 'dart:typed_data';

import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_stream_event.dart';

/// チャットのリポジトリクラス
class ChatRepository {
  /// コンストラクタ
  ChatRepository({required ChatApiClient apiClient}) : _apiClient = apiClient;

  final ChatApiClient _apiClient;

  /// メッセージを送信するメソッド
  Future<String> sendMessage(String prompt, {Uint8List? imageBytes}) async {
    final responseText = await _apiClient.sendMessage(
      prompt,
      imageBytes: imageBytes,
    );

    // AIからの返答が空の場合は例外を投げる
    if (responseText == null || responseText.isEmpty) {
      throw ChatEmptyResponseException();
    }
    return responseText;
  }

  /// メッセージを送信するストリームメソッド（AIのレスポンスにリアルタイムで反応する）
  Stream<ChatStreamEvent> sendMessageStream(
    String prompt, {
    Uint8List? imageBytes,
  }) {
    return _apiClient.sendMessageStream(prompt, imageBytes: imageBytes);
  }

  /// ツール実行結果（1つまたは複数）をAIに送信し、後続の返答ストリームを受信するメソッド
  Stream<ChatStreamEvent> sendFunctionResponseStream(
    List<ChatFunctionResponse> responses,
  ) {
    return _apiClient.sendFunctionResponseStream(responses);
  }
}
