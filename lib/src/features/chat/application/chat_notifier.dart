import 'dart:typed_data';

import 'package:flutter_sample/src/core/utils/date_time_extension.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/uuid_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/chat/application/chat_state.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';
import 'package:flutter_sample/src/features/chat/data/chat_provider.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_notifier.g.dart';

/// チャットのやり取りを管理するプロバーダー
@Riverpod(keepAlive: true)
class ChatNotifier extends _$ChatNotifier {
  /// 進行中リクエストの遮断（Fencing）に使用する世代管理カウンター
  int _generation = 0;

  @override
  ChatState build() {
    // ユーザーIDの変更（別アカウントへの切り替え・ログアウト）をリアクティブに監視
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous != next) {
        ref
            .read(loggerProvider)
            .info('[ChatNotifier] User ID changed. Resetting chat session...');
        clearHistory();
      }
    });

    // 認証状態（ログイン・ログアウト）の変化をリアクティブに監視
    ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
      // ログイン状態からログアウト（false）へ遷移したケースを安全に検知
      if (previous == true && !next) {
        ref
            .read(loggerProvider)
            .info('[ChatNotifier] Signed out. Resetting chat session...');
        clearHistory();
      }
    });

    return const ChatState();
  }

  /// 履歴をクリアし、Geminiのセッションと進行中リクエストを破棄するメソッド
  void clearHistory() {
    // 世代番号を更新して進行中の非同期通信を無効化（Fencing）
    _generation++;
    // Geminiモデル内部の会話セッション（ChatSession）を再生成・破棄
    ref.invalidate(chatRepositoryProvider);
    state = const ChatState();
  }

  /// メッセージを送信するメソッド
  Future<void> sendMessage(String text, {Uint8List? imageBytes}) async {
    // 空文字かつ画像もない場合、または生成中の連打を防ぐ
    if ((text.trim().isEmpty && imageBytes == null) || state.isGenerating) {
      return;
    }

    // 送信開始時点の世代番号を記録（アカウント切り替えやクリア時のFencing用）
    final currentGen = _generation;
    state = state.copyWith(isGenerating: true);

    // 事前にAIのメッセージIDを発行し、ローディングと共に追加
    final targetAiId = ref.read(uuidProvider).v4();
    _addMessageAndLoading(text, targetAiId, imageBytes: imageBytes);

    final talker = ref.read(loggerProvider);
    try {
      final repository = ref.read(chatRepositoryProvider);
      final promptWithTime = _buildPromptWithTime(text);
      final responseText = await repository.sendMessage(
        promptWithTime,
        imageBytes: imageBytes,
      );

      // マウントされていない、または別アカウントへ切り替わった（世代が古い）場合は破棄
      if (!ref.mounted || currentGen != _generation) return;

      final now = ref.read(clockProvider)();

      // IDを指定してAIのメッセージに差し替え（競合対策）
      _updateMessageById(
        targetAiId,
        ChatMessage.ai(id: targetAiId, text: responseText, createdAt: now),
      );
    } on Exception catch (e, st) {
      talker.handle(e, st);
      // マウントされていない、または別アカウントへ切り替わった場合はエラー表示も破棄
      if (!ref.mounted || currentGen != _generation) return;

      final now = ref.read(clockProvider)();
      _updateMessageById(
        targetAiId,
        ChatMessage.error(id: targetAiId, error: e, createdAt: now),
      );
    } finally {
      // 世代が一致する場合のみ生成中フラグを解除（世代不一致の場合はclearHistoryでリセット済み）
      if (ref.mounted && currentGen == _generation) {
        state = state.copyWith(isGenerating: false);
      }
    }
  }

  /// メッセージを送信するメソッド（Stream版）
  Future<void> sendMessageStream(String text, {Uint8List? imageBytes}) async {
    // 空文字かつ画像もない場合、または生成中の連打を防ぐ
    if ((text.trim().isEmpty && imageBytes == null) || state.isGenerating) {
      return;
    }

    // 送信開始時点の世代番号を記録（アカウント切り替えやクリア時のFencing用）
    final currentGen = _generation;
    state = state.copyWith(isGenerating: true);

    // 事前にAIのメッセージIDを発行し、ローディングと共に追加
    final targetAiId = ref.read(uuidProvider).v4();
    _addMessageAndLoading(text, targetAiId, imageBytes: imageBytes);

    final talker = ref.read(loggerProvider);
    try {
      final repository = ref.read(chatRepositoryProvider);
      final promptWithTime = _buildPromptWithTime(text);
      final stream = repository.sendMessageStream(
        promptWithTime,
        imageBytes: imageBytes,
      );

      var aiResponseText = '';
      var isFirstChunk = true;
      late DateTime aiMessageCreatedAt;
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        // マウントされていない、または世代が変更された場合はStream受信を直ちに中断
        if (!ref.mounted || currentGen != _generation) return;

        if (isFirstChunk) {
          // 最初のチャンクが届いた瞬間の時刻を記録
          aiMessageCreatedAt = ref.read(clockProvider)();
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

      // ループ終了後の世代整合性チェック
      if (currentGen != _generation) return;

      if (isFirstChunk) {
        throw ChatEmptyResponseException(); // 空のままStreamが終わった場合
      }
    } on Exception catch (e, st) {
      talker.handle(e, st);
      // マウントされていない、または世代が変更された場合は破棄
      if (!ref.mounted || currentGen != _generation) return;

      final now = ref.read(clockProvider)();
      _updateMessageById(
        targetAiId,
        ChatMessage.error(id: targetAiId, error: e, createdAt: now),
      );
    } finally {
      // 世代が一致する場合のみ生成中フラグを解除
      if (ref.mounted && currentGen == _generation) {
        state = state.copyWith(isGenerating: false);
      }
    }
  }

  /// ユーザーメッセージとローディング状態をセットで追加する
  /// [targetAiId] は後で上書き検索するための目印
  void _addMessageAndLoading(
    String text,
    String targetAiId, {
    Uint8List? imageBytes,
  }) {
    final now = ref.read(clockProvider)();
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage.user(
          id: ref.read(uuidProvider).v4(),
          text: text,
          createdAt: now,
          imageBytes: imageBytes,
        ),
        ChatMessage.loading(id: targetAiId, createdAt: now),
      ],
    );
  }

  /// 状態リストの中から特定のIDを探して新しいメッセージに差し替える
  void _updateMessageById(String targetId, ChatMessage newMessage) {
    state = state.copyWith(
      messages: [
        for (final msg in state.messages)
          if (msg.id == targetId) newMessage else msg,
      ],
    );
  }

  /// AIに送るプロンプトにシステム日時を付加する
  String _buildPromptWithTime(String originalText) {
    final now = ref.read(clockProvider)();
    return '[System Information: Current Time is '
        '${now.toFormattedStringWithTimezone()}]\n$originalText';
  }
}
