// coverage:ignore-file
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';

/// Gemini APIクライアントの実装
class GeminiApiClient implements ChatApiClient {
  /// コンストラクタ
  GeminiApiClient(this._session);
  final ChatSession _session;

  @override
  Future<String?> sendMessage(String prompt) async {
    final response = await _session.sendMessage(Content.text(prompt));
    return response.text;
  }

  @override
  Stream<String?> sendMessageStream(String prompt) {
    return _session
        .sendMessageStream(Content.text(prompt))
        .map((chunk) => chunk.text);
  }
}
