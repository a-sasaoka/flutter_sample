// coverage:ignore-file
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/features/chat/data/chat_repository.dart';
import 'package:flutter_sample/src/features/chat/data/gemini_api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_provider.g.dart';

/// チャットのリポジトリを提供するプロバイダー
@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) {
  final config = ref.watch(envConfigProvider);

  // useAgentPlatform フラグによりエンタープライズ版 (agentPlatform) と
  // 標準デベロッパー版 (googleAI) を使い分ける
  final aiProvider = config.useAgentPlatform
      ? FirebaseAI.agentPlatform()
      : FirebaseAI.googleAI();

  // gemini-3.5 シリーズはデフォルト挙動に任せるため generationConfig を指定しない
  final isGemini35 = config.aiModel.contains('gemini-3.5');

  final model = aiProvider.generativeModel(
    model: config.aiModel,
    generationConfig: isGemini35 ? null : GenerationConfig(temperature: 0.7),
    systemInstruction: Content.system(
      'You are a helpful AI assistant. '
      'Always refer to the [System Information] provided in the user prompt '
      'for current local date, time, and timezone.',
    ),
    tools: [Tool.googleSearch()],
  );

  // GeminiApiClient を生成して注入
  final apiClient = GeminiApiClient(model.startChat());
  return ChatRepository(apiClient: apiClient);
}
