import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';

/// チャットのリポジトリクラス
class ChatRepository {
  /// コンストラクタ
  ChatRepository({required ChatApiClient apiClient}) : _apiClient = apiClient;

  final ChatApiClient _apiClient;

  /// メッセージを送信するメソッド
  Future<String> sendMessage(String prompt) async {
    final responseText = await _apiClient.sendMessage(prompt);

    // AIからの返答が空の場合は例外を投げる
    if (responseText == null || responseText.isEmpty) {
      throw ChatEmptyResponseException();
    }
    return responseText;
  }

  /// メッセージを送信するストリームメソッド（AIのレスポンスにリアルタイムで反応する）
  Stream<String> sendMessageStream(String prompt) {
    return _apiClient.sendMessageStream(prompt).map((text) => text ?? '');
  }
}
