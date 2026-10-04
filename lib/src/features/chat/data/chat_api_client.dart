import 'dart:typed_data';

/// チャットAPIクライアントのインターフェース
abstract class ChatApiClient {
  /// メッセージを送信するメソッド
  Future<String?> sendMessage(String prompt, {Uint8List? imageBytes});

  /// メッセージを送信するストリームメソッド（AIのレスポンスにリアルタイムで反応する）
  Stream<String?> sendMessageStream(String prompt, {Uint8List? imageBytes});
}

/// AIからの返答が空だった時の例外クラス
class ChatEmptyResponseException implements Exception {}
