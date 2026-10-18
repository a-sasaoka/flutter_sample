import 'dart:typed_data';

import 'package:flutter_sample/src/core/actions/app_action_dispatcher.dart';
import 'package:flutter_sample/src/core/utils/date_time_extension.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/uuid_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/chat/application/chat_state.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';
import 'package:flutter_sample/src/features/chat/data/chat_provider.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_action_constants.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_action_type.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_stream_event.dart';
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
      // 認証状態の変化（ログイン・ログアウト）を検知して安全に初期化
      if (previous != next) {
        ref
            .read(loggerProvider)
            .info(
              '[ChatNotifier] Auth state changed. Resetting chat session...',
            );
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
      var stream = repository.sendMessageStream(
        promptWithTime,
        imageBytes: imageBytes,
      );

      var aiResponseText = '';
      var isFirstChunk = true;
      late DateTime aiMessageCreatedAt;
      final buffer = StringBuffer();

      // ツール実行の連鎖（安全のため最大3回までループ保護）
      const maxTurns = 3;
      var currentTurn = 0;

      while (true) {
        final pendingCalls = <ChatStreamEventFunctionCall>[];

        await for (final event in stream) {
          // マウントされていない、または世代が変更された場合はStream受信を直ちに中断
          if (!ref.mounted || currentGen != _generation) return;

          switch (event) {
            case ChatStreamEventText(:final text):
              if (isFirstChunk) {
                // 最初のチャンクが届いた瞬間の時刻を記録
                aiMessageCreatedAt = ref.read(clockProvider)();
                isFirstChunk = false;
              }

              buffer.write(text);
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
            case ChatStreamEventFunctionCall():
              // ツール呼び出し要求を受け取ったらリストに蓄積
              pendingCalls.add(event);
          }
        }

        // ループ終了後の世代整合性チェック
        if (!ref.mounted || currentGen != _generation) return;

        // ツール呼び出し要求がなければ会話終了
        if (pendingCalls.isEmpty) {
          break;
        }

        // 安全装置: 最大ターン数に達している場合は副作用の実行を防ぎセッションをリセット
        if (currentTurn >= maxTurns) {
          ref.invalidate(chatRepositoryProvider);
          throw ChatMaxTurnsExceededException();
        }

        currentTurn++;

        // 2. 蓄積されたツールを順番に特定して実行
        final functionResponses = <ChatFunctionResponse>[];
        final dispatcher = ref.read(appActionDispatcherProvider);
        final uuid = ref.read(uuidProvider);
        final clock = ref.read(clockProvider);

        for (final call in pendingCalls) {
          final actionType = ChatActionType.fromFunctionName(call.name);
          final result = await dispatcher.execute(
            name: call.name,
            args: call.args,
          );

          // 各実行後の世代整合性チェック（安全ガード）
          if (!ref.mounted || currentGen != _generation) return;

          functionResponses.add((
            name: call.name,
            response: result,
            id: call.id,
          ));

          final isError =
              result[ChatActionResultKeys.status] == ChatActionResultKeys.error;
          final now = clock();

          // 画面に表示する多言語パラメータ（タイトルや件数など）を抽出
          final detail = switch (actionType) {
            ChatActionType.createMemo =>
              isError
                  ? null
                  : (result[CreateMemoActionKeys.title] as String? ??
                        call.args[CreateMemoActionKeys.title] as String?),
            ChatActionType.listMemos =>
              isError ? null : result[ListMemosActionKeys.count]?.toString(),
            ChatActionType.changeThemeMode =>
              isError
                  ? null
                  : (result[ChangeThemeActionKeys.theme] as String? ??
                        call.args[ChangeThemeActionKeys.theme] as String?),
            ChatActionType.searchWeb =>
              isError
                  ? null
                  : (result[SearchWebActionKeys.query] as String? ??
                        call.args[SearchWebActionKeys.query] as String?),
            null => null,
          };

          // 3. アクション実行チップをAIローディング（targetAiId）の直前に挿入
          if (actionType != null) {
            _insertMessageBefore(
              targetAiId,
              ChatMessage.action(
                id: uuid.v4(),
                actionType: actionType,
                createdAt: now,
                isError: isError,
                detail: detail,
              ),
            );
          }
        }

        // 4. すべての実行結果をAIに返送して後続ストリームへ移行
        stream = repository.sendFunctionResponseStream(functionResponses);
      }

      // ループ終了後の世代整合性チェック
      if (!ref.mounted || currentGen != _generation) return;

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

  /// 状態リストの特定メッセージIDの手前に新しいメッセージを挿入する
  void _insertMessageBefore(String targetId, ChatMessage newMessage) {
    state = state.copyWith(
      messages: [
        for (final msg in state.messages) ...[
          if (msg.id == targetId) newMessage,
          msg,
        ],
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
