// coverage:ignore-file
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/features/chat/data/chat_repository.dart';
import 'package:flutter_sample/src/features/chat/data/gemini_api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_provider.g.dart';

/// チャットのリポジトリを提供するプロバイダー
@riverpod
ChatRepository chatRepository(Ref ref) {
  final now = ref.watch(currentDateTimeProvider);
  final config = ref.watch(envConfigProvider);
  final year = now.year;
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');

  // Vertex AI Gemini API を利用する場合は vertexAI() を使う
  // Gemini Developer API を利用する場合は googleAI() を使う
  final model = FirebaseAI.vertexAI().generativeModel(
    model: config.aiModel,
    generationConfig: GenerationConfig(temperature: 0.7),
    systemInstruction: Content.system(
      'Current Time is $year-$month-$day $hour:$minute',
    ),
    tools: [Tool.googleSearch()],
  );

  // GeminiApiClient を生成して注入
  final apiClient = GeminiApiClient(model.startChat());
  return ChatRepository(apiClient: apiClient);
}
