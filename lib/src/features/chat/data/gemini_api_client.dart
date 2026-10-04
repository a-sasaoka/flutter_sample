// coverage:ignore-file
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';

/// Gemini APIクライアントの実装
class GeminiApiClient implements ChatApiClient {
  /// コンストラクタ
  GeminiApiClient(this._session);
  final ChatSession _session;

  Content _buildContent(String prompt, Uint8List? imageBytes) {
    if (imageBytes != null && imageBytes.isNotEmpty) {
      return Content.multi([
        TextPart(prompt),
        InlineDataPart('image/jpeg', imageBytes),
      ]);
    }
    return Content.text(prompt);
  }

  @override
  Future<String?> sendMessage(String prompt, {Uint8List? imageBytes}) async {
    final response = await _session.sendMessage(
      _buildContent(prompt, imageBytes),
    );
    return response.text;
  }

  @override
  Stream<String?> sendMessageStream(String prompt, {Uint8List? imageBytes}) {
    return _session
        .sendMessageStream(_buildContent(prompt, imageBytes))
        .map((chunk) => chunk.text);
  }
}
