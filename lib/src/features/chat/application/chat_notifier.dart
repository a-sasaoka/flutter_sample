import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/uuid_provider.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';
import 'package:flutter_sample/src/features/chat/data/chat_provider.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_notifier.g.dart';

/// チャットのやり取りを管理するプロバイダー
@riverpod
class ChatNotifier extends _$ChatNotifier {
  // ストリーミング中（生成中）かどうかを判定する排他制御フラグ
  bool _isGenerating = false;

  @override
  List<ChatMessage> build() {
    // 画面（Notifier）が生きている間は、Repositoryも監視（watch）して破棄させない
    ref.watch(chatRepositoryProvider);
    return [];
  }

  /// メッセージを送信するメソッド
  Future<void> sendMessage(String text) async {
    // 空文字の送信や、生成中の連打を防ぐ
    if (text.trim().isEmpty || _isGenerating) {
      return;
    }

    _isGenerating = true;

    // 事前にAIのメッセージIDを発行し、ローディングと共に追加
    final targetAiId = ref.read(uuidProvider).v4();
    _addMessageAndLoading(text, targetAiId);

    try {
      final repository = ref.read(chatRepositoryProvider);
      final promptWithTime = _buildPromptWithTime(text);
      final responseText = await repository.sendMessage(promptWithTime);

      if (!ref.mounted) {
        return;
      }

      final now = ref.read(currentDateTimeProvider);

      // IDを指定してAIのメッセージに差し替え（競合対策）
      _updateMessageById(
        targetAiId,
        ChatMessage.ai(
          id: targetAiId,
          text: responseText,
          createdAt: now,
        ),
      );
    } on Exception catch (e) {
      if (!ref.mounted) {
        return;
      }

      final now = ref.read(currentDateTimeProvider);
      _updateMessageById(
        targetAiId,
        ChatMessage.error(
          id: targetAiId,
          error: e,
          createdAt: now,
        ),
      );
    } finally {
      _isGenerating = false;
      state = [...state];
    }
  }

  /// メッセージを送信するメソッド（Stream版）
  Future<void> sendMessageStream(String text) async {
    // 空文字の送信や、生成中の連打を防ぐ
    if (text.trim().isEmpty || _isGenerating) {
      return;
    }

    _isGenerating = true;

    // 事前にAIのメッセージIDを発行し、ローディングと共に追加
    final targetAiId = ref.read(uuidProvider).v4();
    _addMessageAndLoading(text, targetAiId);

    try {
      final repository = ref.read(chatRepositoryProvider);
      final promptWithTime = _buildPromptWithTime(text);
      final stream = repository.sendMessageStream(promptWithTime);

      var aiResponseText = '';
      var isFirstChunk = true;
      late DateTime aiMessageCreatedAt;
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        if (!ref.mounted) {
          return;
        }

        if (isFirstChunk) {
          // 最初のチャンクが届いた瞬間の時刻を記録
          aiMessageCreatedAt = ref.read(currentDateTimeProvider);
          isFirstChunk = false;
        }

        buffer.write(chunk);
        aiResponseText = buffer.toString();

        // 既存のIDと時刻を引き継ぎながら、テキストを更新（競合対策）
        _updateMessageById(
          targetAiId,
          ChatMessage.ai(
            id: targetAiId,
            text: aiResponseText,
            createdAt: aiMessageCreatedAt,
          ),
        );
      }

      if (isFirstChunk) {
        throw ChatEmptyResponseException(); // 空のままStreamが終わった場合
      }
    } on Exception catch (e) {
      if (!ref.mounted) {
        return;
      }

      final now = ref.read(currentDateTimeProvider);
      _updateMessageById(
        targetAiId,
        ChatMessage.error(
          id: targetAiId,
          error: e,
          createdAt: now,
        ),
      );
    } finally {
      _isGenerating = false;
      state = [...state];
    }
  }

  /// ユーザーメッセージとローディング状態をセットで追加する
  /// [targetAiId] は後で上書き検索するための目印
  void _addMessageAndLoading(String text, String targetAiId) {
    final now = ref.read(currentDateTimeProvider);
    state = [
      ...state,
      ChatMessage.user(
        id: ref.read(uuidProvider).v4(),
        text: text,
        createdAt: now,
      ),
      ChatMessage.loading(
        id: targetAiId,
        createdAt: now,
      ),
    ];
  }

  /// 状態リストの中から特定のIDを探して新しいメッセージに差し替える
  void _updateMessageById(String targetId, ChatMessage newMessage) {
    state = [
      for (final msg in state)
        if (msg.id == targetId) newMessage else msg,
    ];
  }

  /// AIに送るプロンプトにシステム日時を付加する
  String _buildPromptWithTime(String originalText) {
    final now = ref.read(currentDateTimeProvider);
    return '（※システム情報: 現在時刻は ${now.year}年${now.month}月${now.day}日'
        ' ${now.hour}時${now.minute}分 です）\n$originalText';
  }

  /// UI側でボタンの活性/非活性を制御するためのゲッター
  bool get isGenerating => _isGenerating;
}
