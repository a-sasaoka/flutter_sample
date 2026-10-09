// ignore_for_file: document_ignores, use_setters_to_change_properties

import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/services/image_picker_service.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
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
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../core/widgets/widgets_test_helper.dart';

// --- モッククラス ---

class MockChatRepository extends Mock implements ChatRepository {}

class MockImagePickerService extends Mock implements ImagePickerService {}

class MockTalker extends Mock implements Talker {}

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
  Uint8List? lastSentImageBytes;
  @override
  Future<void> sendMessageStream(String text, {Uint8List? imageBytes}) async {
    lastSentText = text;
    lastSentImageBytes = imageBytes;
  }

  bool clearHistoryCalled = false;
  @override
  void clearHistory() {
    clearHistoryCalled = true;
    state = const ChatState();
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(ImagePickSource.camera);
  });

  late MockAppLocalizations mockL10n;
  late MockChatRepository mockRepo;
  late MockImagePickerService mockImagePickerService;
  late MockTalker mockTalker;

  setUp(() {
    mockL10n = MockAppLocalizations();
    mockRepo = MockChatRepository();
    mockImagePickerService = MockImagePickerService();
    mockTalker = MockTalker();

    when(() => mockL10n.chatTitle).thenReturn('チャット');
    when(() => mockL10n.chatHint).thenReturn('入力してください');
    when(() => mockL10n.thinking).thenReturn('考え中...');
    when(() => mockL10n.chatEmptyMessage).thenReturn('空の返答');
    when(() => mockL10n.chatError).thenReturn('エラー発生');
    when(() => mockL10n.errorUnknown).thenReturn('エラーが発生しました');
    when(() => mockL10n.chartClearAll).thenReturn('すべて削除');
    when(() => mockL10n.chartClearConfirm).thenReturn('削除しますか？');
    when(() => mockL10n.close).thenReturn('閉じる');
    when(() => mockL10n.ok).thenReturn('OK');
    when(() => mockL10n.userListTitle).thenReturn('データ一覧');
    when(() => mockL10n.chatAttachImage).thenReturn('写真を添付');
    when(() => mockL10n.chatCamera).thenReturn('写真を撮る');
    when(() => mockL10n.chatGallery).thenReturn('アルバムから選ぶ');
    when(() => mockL10n.chatRemoveImage).thenReturn('写真を削除');
    when(
      () => mockL10n.chatDefaultPromptWithImage,
    ).thenReturn('この画像について詳しく説明してください');
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
          imagePickerServiceProvider.overrideWithValue(mockImagePickerService),
          loggerProvider.overrideWithValue(mockTalker),
          if (notifier != null) chatProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          localizationsDelegates: [
            MockLocalizationsDelegate(mockL10n),
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
      check(sendButton.onPressed).isNull();

      final circleAvatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      // オフライン時は colorScheme.outline になるはず
      check(
        circleAvatar.backgroundColor,
      ).equals(ThemeData(useMaterial3: true).colorScheme.outline);

      final textField = tester.widget<TextField>(find.byType(TextField));
      check(textField.enabled).equals(true); // テキスト入力は可能なはず
    });

    testWidgets('初期表示: タイトルと入力フォームが表示され、メッセージリストは空であること', (tester) async {
      await setupWidget(tester);

      check(find.text('チャット')).findsOne();
      check(find.byType(TextField)).findsOne();
      check(find.byType(ListView)).findsOne();
      check(find.byIcon(Icons.delete_sweep_outlined)).findsOne();
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

      check(find.text('Hello')).findsOne();
      check(find.text('Hi there!')).findsOne();
      check(find.text('10:30')).findsExactly(2);
    });

    testWidgets('メッセージ描画: ローディングメッセージが正しく表示されること', (tester) async {
      final state = ChatState(
        messages: [
          ChatMessage.loading(id: 'loading', createdAt: DateTime.now()),
        ],
      );
      final notifier = FakeChatNotifier(state);

      await setupWidget(tester, notifier: notifier);
      check(find.byType(ChatBubbleShimmer)).findsOne();
    });

    testWidgets(
      'UI状態: 生成中(isGenerating=true)の時、入力フォームが非活性になり、インジケーターが表示されること',
      (tester) async {
        final notifier = FakeChatNotifier(const ChatState(isGenerating: true));
        await setupWidget(tester, notifier: notifier);

        final textField = tester.widget<TextField>(find.byType(TextField));
        check(textField.enabled).equals(false);
        check(find.text('考え中...')).findsOne();

        final sendButton = tester.widget<IconButton>(
          find.descendant(
            of: find.byType(CircleAvatar),
            matching: find.byType(IconButton),
          ),
        );
        check(sendButton.onPressed).isNull();
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

      check(notifier.lastSentText).equals('Test Message');
      final textField = tester.widget<TextField>(find.byType(TextField));
      check(textField.controller?.text).isNotNull().isEmpty();
    });

    testWidgets('全削除ボタン: キャンセルした場合は何も起きないこと', (tester) async {
      final notifier = FakeChatNotifier();
      await setupWidget(tester, notifier: notifier);

      await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, '閉じる'));
      await tester.pumpAndSettle();

      check(notifier.clearHistoryCalled).equals(false);
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

      check(notifier.clearHistoryCalled).equals(true);
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

      check(find.textContaining('エラー発生')).findsOne();
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

      check(find.text('空の返答')).findsOne();
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
      check(notifier.lastSentText).isNull();
    });

    testWidgets('画面外タップでキーボードが閉じること', (tester) async {
      await setupWidget(tester);
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.tap(textFields.first);
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(textFields.first);
      check(FocusScope.of(context).focusedChild).isNotNull();

      // AppBarなど画面外をタップ
      await tester.tap(find.byType(AppBar));
      await tester.pumpAndSettle();

      check(FocusScope.of(context).focusedChild).isNull();
    });

    testWidgets('画像付きメッセージ: ユーザーメッセージ内にImageウィジェットが描画されること', (tester) async {
      final now = DateTime.now();
      final dummyPng = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);

      final notifier = FakeChatNotifier(
        ChatState(
          messages: [
            ChatMessage.user(
              id: '1',
              text: 'この写真を見て',
              createdAt: now,
              imageBytes: dummyPng,
            ),
          ],
        ),
      );
      await setupWidget(tester, notifier: notifier);
      await tester.pumpAndSettle();

      check(find.text('この写真を見て').evaluate()).isNotEmpty();
      check(find.byType(Image).evaluate()).isNotEmpty();
    });

    testWidgets('写真添付ボタン: ボタンをタップすると撮影・アルバム選択ボトムシートが表示されること', (tester) async {
      await setupWidget(tester);
      await tester.pumpAndSettle();

      final attachButton = find.byIcon(Icons.add_photo_alternate_outlined);
      check(attachButton.evaluate()).isNotEmpty();

      await tester.tap(attachButton);
      await tester.pumpAndSettle();

      check(find.text('写真を撮る').evaluate()).isNotEmpty();
      check(find.text('アルバムから選ぶ').evaluate()).isNotEmpty();
    });

    testWidgets('写真添付: アルバムから写真を選択し、画像のみ送信するとデフォルトプロンプトで送信されること', (
      tester,
    ) async {
      final notifier = FakeChatNotifier();
      final dummyPng = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);
      final dummyFile = XFile.fromData(dummyPng, name: 'test.png');
      when(
        () => mockImagePickerService.pickImage(source: ImagePickSource.gallery),
      ).thenAnswer((_) async => dummyFile);

      await setupWidget(tester, notifier: notifier);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('アルバムから選ぶ'));
      await tester.pumpAndSettle();

      check(find.byIcon(Icons.close).evaluate()).isNotEmpty();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      check(notifier.lastSentText).equals('この画像について詳しく説明してください');
      check(notifier.lastSentImageBytes).isNotNull();
      check(find.byIcon(Icons.close).evaluate()).isEmpty();
    });

    testWidgets('写真添付: プレビューの閉じるボタンをタップすると画像が削除されること', (tester) async {
      final dummyPng = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);
      final dummyFile = XFile.fromData(dummyPng, name: 'test.png');
      when(
        () => mockImagePickerService.pickImage(source: ImagePickSource.camera),
      ).thenAnswer((_) async => dummyFile);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('写真を撮る'));
      await tester.pumpAndSettle();

      check(find.byIcon(Icons.close).evaluate()).isNotEmpty();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      check(find.byIcon(Icons.close).evaluate()).isEmpty();
    });

    testWidgets('写真添付: ボトムシート外をタップしてキャンセルした場合は何も起きないこと', (tester) async {
      await setupWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      check(find.byIcon(Icons.close).evaluate()).isEmpty();
      verifyNever(
        () => mockImagePickerService.pickImage(source: any(named: 'source')),
      );
    });

    testWidgets('写真添付: 権限拒否時にSnackBarが表示されること', (tester) async {
      when(
        () => mockImagePickerService.pickImage(source: any(named: 'source')),
      ).thenThrow(
        const ImagePermissionDeniedException(permission: Permission.camera),
      );

      await setupWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('写真を撮る'));
      await tester.pumpAndSettle();

      check(find.byType(SnackBar).evaluate()).isNotEmpty();
    });

    testWidgets('写真添付: 予期せぬエラー発生時にSnackBarが表示されること', (tester) async {
      when(
        () => mockImagePickerService.pickImage(source: any(named: 'source')),
      ).thenThrow(Exception('Unknown Error'));

      await setupWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('アルバムから選ぶ'));
      await tester.pumpAndSettle();

      check(find.byType(SnackBar).evaluate()).isNotEmpty();
    });

    testWidgets('写真添付: ピッカーで選択をキャンセル（null返却）した場合は何もしないこと', (tester) async {
      when(
        () => mockImagePickerService.pickImage(source: any(named: 'source')),
      ).thenAnswer((_) async => null);

      await setupWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('写真を撮る'));
      await tester.pumpAndSettle();

      check(find.byIcon(Icons.close).evaluate()).isEmpty();
    });
  });
}
