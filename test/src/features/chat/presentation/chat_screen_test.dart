import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/chat/application/chat_notifier.dart';
import 'package:flutter_sample/src/features/chat/application/chat_state.dart';
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
  FakeChatNotifier({
    this.initialState = const [],
    this.initialIsGenerating = false,
  });

  final List<ChatMessage> initialState;

  bool initialIsGenerating;

  String? calledStreamText;

  @override
  ChatState build() =>
      ChatState(messages: initialState, isGenerating: initialIsGenerating);

  @override
  Future<void> sendMessageStream(String text) async {
    calledStreamText = text;
  }

  @override
  Future<void> sendMessage(String text) async {}

  // テスト中のスクロール発火用に状態を更新するヘルパー
  void updateMessages(List<ChatMessage> newMessages) {
    state = state.copyWith(messages: newMessages);
  }

  // テスト中に isGenerating の状態を切り替えてUIを再描画させるヘルパー
  void setGeneratingState({required bool isGenerating}) {
    initialIsGenerating = isGenerating;
    // state を再代入して Riverpod に変更を検知させ、UIをリビルドする
    state = state.copyWith(isGenerating: isGenerating);
  }
}

void main() {
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockL10n = MockAppLocalizations();
    when(() => mockL10n.chatTitle).thenReturn('チャット画面');
    when(() => mockL10n.chatHint).thenReturn('メッセージを入力');
    when(() => mockL10n.chatEmptyMessage).thenReturn('AIからの返答が空でした');
    when(() => mockL10n.thinking).thenReturn('AIが考え中...');
    when(
      () => mockL10n.chatError(any()),
    ).thenAnswer((inv) => 'エラー: ${inv.positionalArguments[0]}');
  });

  /// テスト環境のセットアップヘルパー
  Future<FakeChatNotifier> setupWidget(
    WidgetTester tester, {
    List<ChatMessage> initialMessages = const [],
    bool initialIsGenerating = false,
  }) async {
    final fakeNotifier = FakeChatNotifier(
      initialState: initialMessages,
      initialIsGenerating: initialIsGenerating,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
    final dummyTime = DateTime(2026, 4, 4, 14, 5);

    testWidgets('初期表示: タイトルと入力フォームが表示され、メッセージリストは空であること', (tester) async {
      await setupWidget(tester);

      expect(find.text('チャット画面'), findsOneWidget);
      expect(find.text('メッセージを入力'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('メッセージ描画: 全てのパターンのメッセージと時刻が正しく描画されること', (tester) async {
      final messages = [
        ChatMessage.user(id: '1', text: 'こんにちは', createdAt: dummyTime),
        ChatMessage.ai(id: '2', text: '**太字**のAI返答', createdAt: dummyTime),
        ChatMessage.loading(id: '3', createdAt: dummyTime),
        ChatMessage.error(
          id: '4',
          error: Exception('通信失敗'),
          createdAt: dummyTime,
        ),
        ChatMessage.error(
          id: '5',
          error: ChatEmptyResponseException(),
          createdAt: dummyTime,
        ),
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

      // 6. 時間表示の検証 (loading以外の4つの吹き出しで '14:05' が表示されているか)
      expect(find.text('14:05'), findsNWidgets(4));
    });

    testWidgets('UI状態: 生成中(isGenerating=true)の時、入力フォームとボタンが非活性になること', (
      tester,
    ) async {
      // 最初から生成中の状態で画面を起動する
      final fakeNotifier = await setupWidget(tester, initialIsGenerating: true);

      // 1. TextField の検証
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse, reason: '生成中は入力を受け付けないこと');

      // InputDecoration の hintText を検証
      final inputDecoration = textField.decoration;
      expect(inputDecoration?.hintText, 'AIが考え中...', reason: 'ヒントが変わっていること');

      // 2. 送信ボタン（IconButton）の検証
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull, reason: '生成中はボタンが押せない(null)こと');

      // 3. ボタンの背景色（CircleAvatar）の検証
      final circleAvatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(circleAvatar.backgroundColor, Colors.grey, reason: 'グレーになっていること');

      // --- Act: 生成完了の状態に切り替える ---
      fakeNotifier.setGeneratingState(isGenerating: false);
      await tester.pumpAndSettle();

      // --- Assert: UIが元の活性状態に戻ったか ---
      final restoredTextField = tester.widget<TextField>(
        find.byType(TextField),
      );
      expect(restoredTextField.enabled, isTrue, reason: '入力可能に戻っていること');
      expect(restoredTextField.decoration?.hintText, 'メッセージを入力');

      final restoredIconButton = tester.widget<IconButton>(
        find.byType(IconButton),
      );
      expect(
        restoredIconButton.onPressed,
        isNotNull,
        reason: '再び押せるようになっていること',
      );

      final restoredCircleAvatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(
        restoredCircleAvatar.backgroundColor,
        Colors.blueAccent,
        reason: '元の色に戻っていること',
      );
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
        (i) => ChatMessage.ai(
          id: 'ai_$i',
          text: 'ダミーメッセージ $i',
          createdAt: dummyTime,
        ),
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
        ChatMessage.user(
          id: 'user_1',
          text: '新しいメッセージ',
          createdAt: dummyTime,
        ),
      ]);

      // pumpAndSettleを使うことで、addPostFrameCallbackと
      // 300msのアニメーション（animateTo）が最後まで完了するのを待ちます。
      await tester.pumpAndSettle();

      // Assert: アニメーションでスクロールが完了し、最新のメッセージが画面内に描画されていること
      expect(find.text('新しいメッセージ'), findsOneWidget);
    });

    testWidgets('送信アクション: テキスト入力後にEnterキーを押すと、メソッドが呼ばれフォームがクリアされること', (
      tester,
    ) async {
      final fakeNotifier = await setupWidget(tester);

      final textField = find.byType(TextField);

      // Act: テキストを入力
      await tester.enterText(textField, 'Enterキーで送信！');

      // ソフトウェアキーボードの「完了(Done/Enter)キー」を押した動作をエミュレートし、
      // TextFieldの `onSubmitted` を発火させます。
      await tester.testTextInput.receiveAction(TextInputAction.done);

      await tester.pumpAndSettle();

      // Assert
      // 1. Notifierに正しいテキストが渡されたか
      expect(fakeNotifier.calledStreamText, 'Enterキーで送信！');

      // 2. テキストフィールドが空（クリア）になったか
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.controller?.text, isEmpty);
    });
  });
}
