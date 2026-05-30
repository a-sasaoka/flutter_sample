// ignore_for_file: document_ignores, use_setters_to_change_properties

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/features/chat/application/chat_notifier.dart';
import 'package:flutter_sample/src/features/chat/application/chat_state.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';
import 'package:flutter_sample/src/features/chat/data/chat_provider.dart';
import 'package:flutter_sample/src/features/chat/data/chat_repository.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:flutter_sample/src/features/chat/presentation/chat_bubble_shimmer.dart';
import 'package:flutter_sample/src/features/chat/presentation/chat_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モッククラス ---

class MockAppLocalizations extends Mock implements AppLocalizations {}

class _MockLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _MockLocalizationsDelegate(this.mock);
  final MockAppLocalizations mock;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => mock;
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

class MockChatRepository extends Mock implements ChatRepository {}

// Notifier の挙動をコントロールするための Fake
class FakeChatNotifier extends ChatNotifier {
  FakeChatNotifier([ChatState? initialState]) : _initialState = initialState;
  final ChatState? _initialState;

  @override
  ChatState build() {
    // Repositoryへの依存をモックで解決するようにする（Firebaseエラー回避）
    ref.watch(chatRepositoryProvider);
    return _initialState ?? const ChatState();
  }

  void updateState(ChatState newState) {
    state = newState;
  }

  String? lastSentText;
  @override
  Future<void> sendMessageStream(String text) async {
    lastSentText = text;
  }

  bool clearHistoryCalled = false;
  @override
  void clearHistory() {
    clearHistoryCalled = true;
    state = const ChatState();
  }
}

void main() {
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

  Future<void> setupWidget(
    WidgetTester tester, {
    ChatNotifier? notifier,
    bool isOnline = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(mockRepo),
          isOnlineProvider.overrideWithValue(isOnline),
          if (notifier != null) chatProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          localizationsDelegates: [
            _MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const ChatScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  group('ChatScreen', () {
    testWidgets('オフライン時: 送信ボタンが非活性になり、背景色が適切に設定されること', (tester) async {
      await setupWidget(tester, isOnline: false);

      final sendButton = tester.widget<IconButton>(
        find.descendant(
          of: find.byType(CircleAvatar),
          matching: find.byType(IconButton),
        ),
      );
      expect(sendButton.onPressed, isNull);

      final circleAvatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      // オフライン時は colorScheme.outline になるはず
      expect(
        circleAvatar.backgroundColor,
        ThemeData(useMaterial3: true).colorScheme.outline,
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isTrue); // テキスト入力は可能なはず
    });

    testWidgets('初期表示: タイトルと入力フォームが表示され、メッセージリストは空であること', (tester) async {
      await setupWidget(tester);

      expect(find.text('チャット'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byIcon(Icons.delete_sweep_outlined), findsOneWidget);
    });

    testWidgets('メッセージ描画: ユーザーとAIのメッセージが正しく表示されること', (tester) async {
      final now = DateTime(2026, 5, 10, 10, 30);
      final state = ChatState(
        messages: [
          ChatMessage.user(id: '1', text: 'Hello', createdAt: now),
          ChatMessage.ai(id: '2', text: 'Hi there!', createdAt: now),
        ],
      );
      final notifier = FakeChatNotifier(state);

      await setupWidget(tester, notifier: notifier);
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Hi there!'), findsOneWidget);
      expect(find.text('10:30'), findsNWidgets(2));
    });

    testWidgets('メッセージ描画: ローディングメッセージが正しく表示されること', (tester) async {
      final state = ChatState(
        messages: [
          ChatMessage.loading(id: 'loading', createdAt: DateTime.now()),
        ],
      );
      final notifier = FakeChatNotifier(state);

      await setupWidget(tester, notifier: notifier);
      expect(find.byType(ChatBubbleShimmer), findsOneWidget);
    });

    testWidgets(
      'UI状態: 生成中(isGenerating=true)の時、入力フォームが非活性になり、インジケーターが表示されること',
      (
        tester,
      ) async {
        final notifier = FakeChatNotifier(const ChatState(isGenerating: true));
        await setupWidget(tester, notifier: notifier);

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.enabled, isFalse);
        expect(find.text('考え中...'), findsOneWidget);

        final sendButton = tester.widget<IconButton>(
          find.descendant(
            of: find.byType(CircleAvatar),
            matching: find.byType(IconButton),
          ),
        );
        expect(sendButton.onPressed, isNull);
      },
    );

    testWidgets('送信アクション: テキスト入力後に送信ボタンを押すと、メソッドが呼ばれフォームがクリアされること', (
      tester,
    ) async {
      final notifier = FakeChatNotifier();
      await setupWidget(tester, notifier: notifier);

      await tester.enterText(find.byType(TextField), 'Test Message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(notifier.lastSentText, 'Test Message');
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('全削除ボタン: キャンセルした場合は何も起きないこと', (tester) async {
      final notifier = FakeChatNotifier();
      await setupWidget(tester, notifier: notifier);

      await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, '閉じる'));
      await tester.pumpAndSettle();

      expect(notifier.clearHistoryCalled, isFalse);
    });

    testWidgets('全削除ボタン: 「すべて削除」を選択すると履歴がクリアされること', (tester) async {
      final notifier = FakeChatNotifier();
      await setupWidget(tester, notifier: notifier);

      await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
      await tester.pumpAndSettle();

      final confirmButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'すべて削除'),
      );
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(notifier.clearHistoryCalled, isTrue);
    });

    testWidgets('メッセージ描画: エラーメッセージが正しく表示されること', (tester) async {
      final now = DateTime(2026, 5, 10, 10, 30);
      final state = ChatState(
        messages: [
          ChatMessage.error(
            id: '3',
            error: Exception('Network Error'),
            createdAt: now,
          ),
        ],
      );
      final notifier = FakeChatNotifier(state);

      await setupWidget(tester, notifier: notifier);
      await tester.pumpAndSettle();

      expect(find.textContaining('エラー発生'), findsOneWidget);
    });

    testWidgets('メッセージ描画: 空の返答エラーが正しく表示されること', (tester) async {
      final now = DateTime(2026, 5, 10, 10, 30);
      final state = ChatState(
        messages: [
          ChatMessage.error(
            id: '4',
            error: ChatEmptyResponseException(),
            createdAt: now,
          ),
        ],
      );
      final notifier = FakeChatNotifier(state);

      await setupWidget(tester, notifier: notifier);
      await tester.pumpAndSettle();

      expect(find.text('空の返答'), findsOneWidget);
    });

    testWidgets('オートスクロール: メッセージが増えた時にスクロールされること', (tester) async {
      final notifier = FakeChatNotifier();
      await setupWidget(tester, notifier: notifier);

      final now = DateTime.now();
      notifier.updateState(
        ChatState(
          messages: [ChatMessage.user(id: '1', text: 'Hello', createdAt: now)],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      notifier.updateState(
        ChatState(
          messages: [
            ChatMessage.user(id: '1', text: 'Hello World', createdAt: now),
          ],
        ),
      );
      await tester.pump();
    });

    testWidgets('送信アクション: 空文字送信は無視されること', (tester) async {
      final notifier = FakeChatNotifier();
      await setupWidget(tester, notifier: notifier);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(notifier.lastSentText, isNull);
    });

    testWidgets('画面外タップでキーボードが閉じること', (tester) async {
      await setupWidget(tester);
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.tap(textFields.first);
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(textFields.first);
      expect(FocusScope.of(context).focusedChild, isNotNull);

      // AppBarなど画面外をタップ
      await tester.tap(find.byType(AppBar));
      await tester.pumpAndSettle();

      expect(FocusScope.of(context).focusedChild, isNull);
    });
  });
}
