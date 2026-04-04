import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/chat/application/chat_notifier.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:flutter_sample/src/features/chat/presentation/chat_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モックとデリゲート ---
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

// --- Fake Notifier ---
// Riverpodの AutoDisposeNotifier を継承し、ChatNotifierのフリをする
class FakeChatNotifier extends ChatNotifier {
  FakeChatNotifier(this.initialState);
  final List<ChatMessage> initialState;

  String? calledStreamText;

  @override
  List<ChatMessage> build() => initialState;

  @override
  Future<void> sendMessageStream(String text) async {
    calledStreamText = text;
  }

  @override
  Future<void> sendMessage(String text) async {}

  // テスト中のスクロール発火用に状態を更新するヘルパー
  // ignore: use_setters_to_change_properties
  void updateMessages(List<ChatMessage> newMessages) {
    state = newMessages;
  }
}

void main() {
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockL10n = MockAppLocalizations();
    when(() => mockL10n.chatTitle).thenReturn('チャット画面');
    when(() => mockL10n.chatHint).thenReturn('メッセージを入力');
    when(() => mockL10n.chatEmptyMessage).thenReturn('AIからの返答が空でした');
    when(
      () => mockL10n.chatError(any()),
    ).thenAnswer((inv) => 'エラー: ${inv.positionalArguments[0]}');
  });

  /// テスト環境のセットアップヘルパー
  Future<FakeChatNotifier> setupWidget(
    WidgetTester tester, {
    List<ChatMessage> initialMessages = const [],
  }) async {
    final fakeNotifier = FakeChatNotifier(initialMessages);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // UI側で ref.watch(chatProvider) が使われている前提
          chatProvider.overrideWith(() => fakeNotifier),
        ],
        child: MaterialApp(
          localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
          home: const ChatScreen(),
        ),
      ),
    );
    await tester.pump();
    return fakeNotifier;
  }

  group('ChatScreen', () {
    testWidgets('初期表示: タイトルと入力フォームが表示され、メッセージリストは空であること', (tester) async {
      await setupWidget(tester);

      expect(find.text('チャット画面'), findsOneWidget);
      expect(find.text('メッセージを入力'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('メッセージ描画: 全てのパターンのメッセージが正しく描画されること', (tester) async {
      final messages = [
        const ChatMessage.user(text: 'こんにちは'),
        const ChatMessage.ai(text: '**太字**のAI返答'), // Markdownのテスト用
        const ChatMessage.loading(),
        ChatMessage.error(error: Exception('通信失敗')),
        ChatMessage.error(error: ChatEmptyResponseException()), // 特殊エラーの分岐用
      ];

      await setupWidget(tester, initialMessages: messages);

      // 1. Userメッセージの検証
      expect(find.text('こんにちは'), findsOneWidget);

      // 2. AIメッセージの検証 (MarkdownBodyが使われているか)
      expect(find.byType(MarkdownBody), findsNWidgets(3));

      // 3. Loadingの検証
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 4. 通常のExceptionの検証
      expect(find.text('エラー: Exception: 通信失敗'), findsOneWidget);

      // 5. ChatEmptyResponseException の特殊文言の検証
      expect(find.text('AIからの返答が空でした'), findsOneWidget);
    });

    testWidgets('送信アクション: テキスト入力後に送信ボタンを押すと、メソッドが呼ばれフォームがクリアされること', (
      tester,
    ) async {
      final fakeNotifier = await setupWidget(tester);

      // Act: テキストを入力して送信
      final textField = find.byType(TextField);
      await tester.enterText(textField, '今日の天気は？');
      await tester.tap(find.byIcon(Icons.send));

      // 描画の完了を待つ
      await tester.pumpAndSettle();

      // Assert
      // 1. Notifierに正しいテキストが渡されたか
      expect(fakeNotifier.calledStreamText, '今日の天気は？');

      // 2. テキストフィールドが空（クリア）になったか
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.controller?.text, isEmpty);
    });

    testWidgets('オートスクロール: メッセージが追加されるとリストが一番下までスクロールすること', (tester) async {
      // 画面に収まりきらない大量のメッセージを初期配置する
      final initialMessages = List.generate(
        20,
        (i) => ChatMessage.ai(text: 'ダミーメッセージ $i'),
      );

      final fakeNotifier = await setupWidget(
        tester,
        initialMessages: initialMessages,
      );

      // この時点で画面外にあるメッセージは描画されていない
      expect(find.text('新しいメッセージ'), findsNothing);

      // Act: 新しいメッセージをStateに追加（ref.listenが発火する）
      fakeNotifier.updateMessages([
        ...initialMessages,
        const ChatMessage.user(text: '新しいメッセージ'),
      ]);

      // pumpAndSettleを使うことで、addPostFrameCallbackと
      // 300msのアニメーション（animateTo）が最後まで完了するのを待ちます。
      await tester.pumpAndSettle();

      // Assert: アニメーションでスクロールが完了し、最新のメッセージが画面内に描画されていること
      expect(find.text('新しいメッセージ'), findsOneWidget);
    });
  });
}
