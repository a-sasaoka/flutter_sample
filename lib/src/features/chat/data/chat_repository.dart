import 'package:firebase_ai/firebase_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_repository.g.dart';

/// AIからの返答が空だった時の例外クラス
class ChatEmptyResponseException implements Exception {}

/// チャットのリポジトリクラスのプロバイダー
@riverpod
ChatRepository chatRepository(Ref ref) {
  return ChatRepository();
}

/// チャットのリポジトリクラス
class ChatRepository {
  /// コンストラクタ
  ChatRepository() {
    // Vertex AI Gemini API を利用する場合は vertexAI() を使う
    // Gemini Developer API を利用する場合は googleAI() を使う
    _model = FirebaseAI.vertexAI().generativeModel(
      model: _modelName,
      generationConfig: GenerationConfig(temperature: 0.7),
    );
  }

  /// 使用するモデル
  static const String _modelName = 'gemini-2.5-flash';

  late final GenerativeModel _model;

  /// メッセージを送信するメソッド
  Future<String> sendMessage(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);

    // AIからの返答が空の場合は例外を投げる
    if (response.text == null || response.text!.isEmpty) {
      throw ChatEmptyResponseException();
    }
    return response.text!;
  }
}
