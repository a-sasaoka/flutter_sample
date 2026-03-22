import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_repository.g.dart';

/// AIからの返答が空だった時の例外クラス
class ChatEmptyResponseException implements Exception {}

// coverage:ignore-start
/// チャットのリポジトリクラスのプロバイダー
/// ※ Riverpodの初期化処理であり、内部でFirebase初期化を伴うためカバレッジから除外
@riverpod
ChatRepository chatRepository(Ref ref) {
  // プロバイダーから現在日時を取得
  final now = ref.watch(currentDateTimeProvider);

  // 取得した日時を Repository のコンストラクタに注入（DI）
  return ChatRepository(now: now);
}
// coverage:ignore-end

/// チャットAPIクライアントのインターフェース
abstract class ChatApiClient {
  /// メッセージを送信するメソッド
  Future<String?> sendMessage(String prompt);

  /// メッセージを送信するストリームメソッド（AIのレスポンスにリアルタイムで反応する）
  Stream<String?> sendMessageStream(String prompt);
}

// coverage:ignore-start
/// Gemini APIクライアントクラス
/// ※ 外部SDK(Firebase)のfinalクラスに依存しており、通信が発生するためカバレッジから除外
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
// coverage:ignore-end

/// チャットのリポジトリクラス
class ChatRepository {
  /// コンストラクタ
  ChatRepository({required DateTime now, ChatApiClient? apiClient}) {
    // テスト用のAPIクライアントが渡された場合はそれを使う
    if (apiClient != null) {
      _apiClient = apiClient;
      return;
    }

    // coverage:ignore-start
    // ※ ここから下は実際のFirebase通信準備のためカバレッジから除外
    // チャットを開いた時間を取得する
    final dateString =
        '${now.year}年${now.month}月${now.day}日 ${now.hour}時${now.minute}分';

    // Vertex AI Gemini API を利用する場合は vertexAI() を使う
    // Gemini Developer API を利用する場合は googleAI() を使う
    final model = FirebaseAI.vertexAI().generativeModel(
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

    _apiClient = GeminiApiClient(model.startChat());
    // coverage:ignore-end
  }

  /// 使用するモデル
  static final String _modelName = AppEnv.aiModel; // coverage:ignore-line

  /// APIクライアント

  late final ChatApiClient _apiClient;

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
