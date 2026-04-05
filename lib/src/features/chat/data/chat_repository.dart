import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_repository.g.dart';

/// AIからの返答が空だった時の例外クラス
class ChatEmptyResponseException implements Exception {}

/// チャットのリポジトリクラスのプロバイダー
@riverpod
ChatRepository chatRepository(Ref ref) {
  // プロバイダーから現在日時を取得
  final now = ref.watch(currentDateTimeProvider);

  // 取得した日時を Repository のコンストラクタに注入（DI）
  return ChatRepository(now: now);
}

/// チャットのリポジトリクラス
class ChatRepository {
  /// コンストラクタ
  ChatRepository({required DateTime now}) {
    // チャットを開いた時間を取得する
    final dateString =
        '${now.year}年${now.month}月${now.day}日 ${now.hour}時${now.minute}分';

    // Vertex AI Gemini API を利用する場合は vertexAI() を使う
    // Gemini Developer API を利用する場合は googleAI() を使う
    _model = FirebaseAI.vertexAI().generativeModel(
      model: _modelName,
      generationConfig: GenerationConfig(temperature: 0.7),
      // systemInstruction（システムプロンプト）を使って、AIに現在日時を教える
      // ただし、この方法だと日付が変わったことは認識できない
      systemInstruction: Content.system(
        '現在の日時は $dateString です。',
      ),
      // 最新情報を取得できるようにGoogle検索の利用許可を与える
      tools: [
        Tool.googleSearch(),
      ],
    );

    _chatSession = _model.startChat();
  }

  /// 使用するモデル
  static final String _modelName = AppEnv.aiModel;

  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  /// メッセージを送信するメソッド
  Future<String> sendMessage(String prompt) async {
    final response = await _chatSession.sendMessage(Content.text(prompt));

    // AIからの返答が空の場合は例外を投げる
    if (response.text == null || response.text!.isEmpty) {
      throw ChatEmptyResponseException();
    }
    return response.text!;
  }

  /// メッセージを送信するストリームメソッド（AIのレスポンスにリアルタイムで反応する）
  Stream<String> sendMessageStream(String prompt) {
    // sendMessage ではなく sendMessageStream を使うのがポイント
    return _chatSession.sendMessageStream(Content.text(prompt)).map((chunk) {
      // チャンク（文字の断片）からテキスト部分だけを抽出して流す
      return chunk.text ?? '';
    });
  }
}
