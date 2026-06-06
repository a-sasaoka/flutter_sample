import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/features/chat/application/chat_notifier.dart';
import 'package:flutter_sample/src/features/chat/application/chat_state.dart';
import 'package:flutter_sample/src/features/chat/data/chat_provider.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:flutter_sample/src/features/chat/presentation/chat_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'chat_screen_test.dart';

void main() {
  group('ChatScreen Golden Tests', () {
    late MockAppLocalizations mockL10n;
    late MockChatRepository mockRepo;

    setUp(() {
      mockL10n = MockAppLocalizations();
      mockRepo = MockChatRepository();

      when(() => mockL10n.chatTitle).thenReturn('チャット');
      when(() => mockL10n.chatHint).thenReturn('入力してください');
      when(() => mockL10n.thinking).thenReturn('考え中...');
      when(() => mockL10n.chatEmptyMessage).thenReturn('空の返答');
      when(() => mockL10n.chatError(any())).thenReturn('エラー発生');
      when(() => mockL10n.chartClearAll).thenReturn('すべて削除');
      when(() => mockL10n.chartClearConfirm).thenReturn('削除しますか？');
      when(() => mockL10n.close).thenReturn('閉じる');
      when(() => mockL10n.ok).thenReturn('OK');
      when(() => mockL10n.userListTitle).thenReturn('データ一覧');
    });

    Widget buildChatForGolden({required ChatState state}) {
      final notifier = FakeChatNotifier(state);

      return ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          isOnlineProvider.overrideWithValue(true),
          chatProvider.overrideWith(() => notifier),
        ],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
          ),
          child: MaterialApp(
            theme: AppTheme.light().copyWith(
              textTheme: AppTheme.light().textTheme.apply(
                fontFamily: 'NotoSansJP',
              ),
            ),
            localizationsDelegates: [
              MockLocalizationsDelegate(mockL10n),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const ChatScreen(),
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
    }

    // ignore: discarded_futures, testing framework registers tests synchronously
    goldenTest(
      'ChatScreen の描画 (会話中/思考中)',
      fileName: 'chat_screen',
      pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Conversation State',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildChatForGolden(
                state: ChatState(
                  messages: [
                    ChatMessage.user(
                      id: '1',
                      text: 'こんにちは！お腹が空きました。',
                      createdAt: DateTime(2026, 6, 6, 12),
                    ),
                    ChatMessage.ai(
                      id: '2',
                      text: 'こんにちは！今日のランチには美味しいパスタはいかがですか？🍝',
                      createdAt: DateTime(2026, 6, 6, 12, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Thinking State',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildChatForGolden(
                state: ChatState(
                  messages: [
                    ChatMessage.user(
                      id: '1',
                      text: 'パスタのレシピを教えてください。',
                      createdAt: DateTime(2026, 6, 6, 12, 2),
                    ),
                    ChatMessage.loading(
                      id: 'loading',
                      createdAt: DateTime(2026, 6, 6, 12, 2),
                    ),
                  ],
                  isGenerating: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
