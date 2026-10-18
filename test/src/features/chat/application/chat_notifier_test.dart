import 'dart:async';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/actions/app_action_dispatcher.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/uuid_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/chat/application/chat_notifier.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';
import 'package:flutter_sample/src/features/chat/data/chat_provider.dart';
import 'package:flutter_sample/src/features/chat/data/chat_repository.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_action_constants.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_action_type.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_stream_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

// --- Test Auth Notifiers ---
// 認証状態の動的変化をシミュレートするためのテスト用Notifier
class TestUserIdNotifier extends Notifier<String?> {
  @override
  String? build() => 'initial-user';
  String? get userId => state;
  set userId(String? id) => state = id;
}

final testUserIdProvider = NotifierProvider<TestUserIdNotifier, String?>(
  TestUserIdNotifier.new,
);

class TestAuthNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  bool get isAuthenticated => state;
  set isAuthenticated(bool value) => state = value;
}

final testAuthNotifierProvider = NotifierProvider<TestAuthNotifier, bool>(
  TestAuthNotifier.new,
);

// --- Fake AppActionDispatcher ---
class FakeAppActionDispatcher extends Fake implements AppActionDispatcher {
  Map<String, Object?> responseToReturn = {
    ChatActionResultKeys.status: ChatActionResultKeys.success,
  };
  String? lastExecutedName;
  Map<String, Object?>? lastExecutedArgs;
  int executeCallCount = 0;
  Future<void> Function()? onExecute;

  @override
  Future<Map<String, Object?>> execute({
    required String name,
    required Map<String, Object?> args,
  }) async {
    executeCallCount++;
    lastExecutedName = name;
    lastExecutedArgs = args;
    if (onExecute != null) {
      await onExecute!();
    }
    // 実際の非同期処理（DB操作等）と同様にイベントループを回して状態通知を反映
    await Future<void>.delayed(Duration.zero);
    return responseToReturn;
  }
}

// --- Fake Repository ---
// Streamの挙動を完全にコントロールするためのFakeクラス
class FakeChatRepository extends Fake implements ChatRepository {
  Exception? exceptionToThrow;
  Exception? streamExceptionToThrow;
  bool shouldThrow = false;
  bool shouldStreamThrow = false;
  bool streamEmpty = false;

  // 排他制御（連打防止）が正しく機能しているか確認するためのカウンター
  int sendMessageCallCount = 0;
  int sendMessageStreamCallCount = 0;
  int sendFunctionResponseStreamCallCount = 0;

  // Streamで流す分割された文字列（チャンク）
  List<String> streamChunks = ['AI', 'からの', '返答です'];

  // カスタムイベントリスト（設定されている場合はこちらを流す）
  List<ChatStreamEvent>? customStreamEvents;
  List<ChatStreamEvent>? customFunctionResponseEvents;

  // 複数ターンの関数レスポンスイベントリスト
  List<List<ChatStreamEvent>> multiTurnFunctionResponseEvents = [];
  int _functionResponseTurnIndex = 0;

  // 関数レスポンスストリームの引数記録
  String? lastFunctionName;
  Map<String, Object?>? lastFunctionResponse;
  String? lastFunctionId;
  List<ChatFunctionResponse>? lastFunctionResponses;

  // Streamに渡された最終的なテキスト（日時コンテキスト検証用）
  String? lastStreamText;

  // 渡された画像データ（マルチモーダル検証用）
  Uint8List? lastSentImageBytes;
  Uint8List? lastStreamImageBytes;

  @override
  Future<String> sendMessage(String text, {Uint8List? imageBytes}) async {
    sendMessageCallCount++;
    lastSentImageBytes = imageBytes;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (shouldThrow) throw Exception('API Error');
    // 非同期処理（生成中）をシミュレートするため少し待つ
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return '単発のAI返答';
  }

  @override
  Stream<ChatStreamEvent> sendMessageStream(
    String text, {
    Uint8List? imageBytes,
  }) async* {
    sendMessageStreamCallCount++;
    lastStreamText = text;
    lastStreamImageBytes = imageBytes;

    if (streamExceptionToThrow != null) throw streamExceptionToThrow!;
    if (shouldStreamThrow) throw Exception('Stream API Error');
    if (streamEmpty) return; // 空のStreamを返して終了

    if (customStreamEvents != null) {
      for (final event in customStreamEvents!) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        yield event;
      }
      return;
    }

    for (final chunk in streamChunks) {
      // Streamが徐々に流れてくる様子をシミュレート（生成中の隙間を作る）
      await Future<void>.delayed(const Duration(milliseconds: 20));
      yield ChatStreamEvent.text(chunk);
    }
  }

  @override
  Stream<ChatStreamEvent> sendFunctionResponseStream(
    List<ChatFunctionResponse> responses,
  ) async* {
    sendFunctionResponseStreamCallCount++;
    lastFunctionResponses = responses;
    if (responses.isNotEmpty) {
      lastFunctionName = responses.first.name;
      lastFunctionResponse = responses.first.response;
      lastFunctionId = responses.first.id;
    }

    if (multiTurnFunctionResponseEvents.isNotEmpty &&
        _functionResponseTurnIndex < multiTurnFunctionResponseEvents.length) {
      final events =
          multiTurnFunctionResponseEvents[_functionResponseTurnIndex++];
      for (final event in events) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        yield event;
      }
      return;
    }

    if (customFunctionResponseEvents != null) {
      for (final event in customFunctionResponseEvents!) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        yield event;
      }
      return;
    }

    for (final chunk in streamChunks) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      yield ChatStreamEvent.text(chunk);
    }
  }
}

// --- Fake Uuid ---
// ランダムな UUID 生成を固定化・予測可能にするための Fake クラス
class FakeUuid extends Fake implements Uuid {
  int _counter = 0;
  @override
  String v4({V4Options? config, Map<String, dynamic>? options}) {
    _counter++;
    return 'fake-uuid-$_counter';
  }
}

class HandleCall {
  const HandleCall({required this.exception, this.stackTrace});

  final Object exception;
  final StackTrace? stackTrace;
}

class SpyTalker extends Talker {
  SpyTalker() : super(settings: TalkerSettings(enabled: false));

  final List<HandleCall> handleCalls = [];

  @override
  void handle(Object exception, [StackTrace? stackTrace, dynamic msg]) {
    handleCalls.add(HandleCall(exception: exception, stackTrace: stackTrace));
    super.handle(exception, stackTrace, msg);
  }
}

void main() {
  late SpyTalker spyTalker;

  setUp(() {
    spyTalker = SpyTalker();
  });

  /// テスト環境のセットアップヘルパー
  ProviderContainer createContainer(
    FakeChatRepository fakeRepo, {
    FakeAppActionDispatcher? fakeDispatcher,
    void Function(Ref)? onRepoInit,
  }) {
    // 現在時刻を固定して、システム情報の文字列を完全に予測可能にする
    final fixedDateTime = DateTime(2026, 3, 21, 10);

    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWith((ref) {
          onRepoInit?.call(ref);
          return fakeRepo;
        }),
        appActionDispatcherProvider.overrideWithValue(
          fakeDispatcher ?? FakeAppActionDispatcher(),
        ),
        clockProvider.overrideWithValue(() => fixedDateTime),
        uuidProvider.overrideWithValue(FakeUuid()),
        loggerProvider.overrideWithValue(spyTalker),
        currentUserIdProvider.overrideWith(
          (ref) => ref.watch(testUserIdProvider),
        ),
        isAuthenticatedProvider.overrideWith(
          (ref) => ref.watch(testAuthNotifierProvider),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.listen(chatProvider, (_, _) {});

    return container;
  }

  group('ChatNotifier', () {
    test('初期化: build() は空のリストを返すこと', () {
      final fakeRepo = FakeChatRepository();
      final container = createContainer(fakeRepo);

      final state = container.read(chatProvider);

      check(state.messages).isEmpty();
    });

    group('sendMessage (単発送信)', () {
      test('空文字の場合は何もしないこと', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessage('   '); // スペースのみ

        check(container.read(chatProvider).messages).isEmpty();
        check(fakeRepo.sendMessageCallCount).equals(0); // 呼ばれていないこと
      });

      test('正常系: ユーザーのメッセージとAIの返答がstateに追加されること', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessage('こんにちは');

        final state = container.read(chatProvider);

        check(state.messages.length).equals(2);
        check(state.messages.first).isA<ChatMessageUser>();
        check(state.messages.first.toString()).contains('こんにちは');

        check(state.messages.last).isA<ChatMessageAi>();
        check(state.messages.last.toString()).contains('単発のAI返答');
      });

      test('排他制御: 生成中に連続で送信しても、2回目以降は無視されること', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        // 1回目を await せずに実行し、状態を生成中（isGenerating = true）にする
        final future1 = notifier.sendMessage('1回目');

        // 瞬時に2回目を実行（ブロックされるはず）
        final future2 = notifier.sendMessage('2回目');

        // 両方の完了を待つ
        await Future.wait([future1, future2]);

        final state = container.read(chatProvider);

        // 結果検証: リポジトリは1回しか呼ばれておらず、リストも2つ（1回目の質問と答え）のみ
        check(fakeRepo.sendMessageCallCount).equals(1);
        check(state.messages.length).equals(2);
        check(state.messages.first.toString()).contains('1回目');
      });

      test('異常系: 例外が発生した場合、対象の要素がエラーメッセージに差し替わること', () async {
        final expectedException = Exception('API Error');
        final fakeRepo = FakeChatRepository()
          ..exceptionToThrow = expectedException;
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessage('こんにちは');

        final state = container.read(chatProvider);

        check(state.messages.length).equals(2);
        check(state.messages.last).isA<ChatMessageError>();
        check(spyTalker.handleCalls).length.equals(1);
        check(spyTalker.handleCalls.first.exception).equals(expectedException);
        check(spyTalker.handleCalls.first.stackTrace).isNotNull();
      });

      test('画像付き送信: ユーザーメッセージに画像データが保持されリポジトリに渡されること', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);
        final dummyBytes = Uint8List.fromList([1, 2, 3]);

        await notifier.sendMessage('画像付き', imageBytes: dummyBytes);

        final state = container.read(chatProvider);
        final userMessage = state.messages.first as ChatMessageUser;
        check(userMessage.text).equals('画像付き');
        check(userMessage.imageBytes).equals(dummyBytes);
        check(fakeRepo.lastSentImageBytes).equals(dummyBytes);
      });
    });

    group('sendMessageStream (Stream送信)', () {
      test('空文字の場合は何もしないこと', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessageStream('   ');

        check(container.read(chatProvider).messages).isEmpty();
        check(fakeRepo.sendMessageStreamCallCount).equals(0);
      });

      test('正常系: システム日時が付与され、Streamから届くチャンクが結合されていくこと', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo)
          ..listen(chatProvider, (_, _) {});

        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessageStream('ストリームテスト');

        final state = container.read(chatProvider);

        // 1. 結合されたメッセージの検証
        check(state.messages.length).equals(2);
        check(state.messages.last).isA<ChatMessageAi>();
        check(state.messages.last.toString()).contains('AIからの返答です');

        // 2. 日付コンテキスト（システム情報）が正しく Repository に渡されたかの検証
        check(fakeRepo.lastStreamText).isNotNull()
          ..contains(
            '[System Information: Current Time is 2026-03-21 10:00 (Timezone:',
          )
          ..endsWith('\nストリームテスト');
      });

      test('排他制御: Stream生成中に連続で送信しても、2回目以降は無視されること', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        // 1回目を await せずに実行
        final future1 = notifier.sendMessageStream('1回目のStream');

        check(
          container.read(chatProvider).isGenerating,
        ).equals(true); // 生成中になっていること

        // 瞬時に2回目を実行（ブロックされるはず）
        final future2 = notifier.sendMessageStream('2回目のStream');

        // 両方の完了を待つ
        await Future.wait([future1, future2]);

        final state = container.read(chatProvider);

        check(state.isGenerating).equals(false); // 生成が終わっていること
        check(fakeRepo.sendMessageStreamCallCount).equals(1);
        check(state.messages.length).equals(2);
      });

      test(
        '異常系: Stream が空っぽで終わった場合、ChatEmptyResponseException としてエラー表示になること',
        () async {
          final fakeRepo = FakeChatRepository()..streamEmpty = true;
          final container = createContainer(fakeRepo);
          final notifier = container.read(chatProvider.notifier);

          await notifier.sendMessageStream('空のStream');

          final state = container.read(chatProvider);

          check(state.messages.length).equals(2);
          check(state.messages.last).isA<ChatMessageError>();
          check(
            state.messages.last.toString(),
          ).contains('ChatEmptyResponseException');
          check(spyTalker.handleCalls).length.equals(1);
          check(
            spyTalker.handleCalls.first.exception,
          ).isA<ChatEmptyResponseException>();
          check(spyTalker.handleCalls.first.stackTrace).isNotNull();
        },
      );

      test('異常系: Stream の途中で例外が発生した場合、対象要素がエラー表示になること', () async {
        final expectedException = Exception('Stream API Error');
        final fakeRepo = FakeChatRepository()
          ..streamExceptionToThrow = expectedException;
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessageStream('エラーが起きるStream');

        final state = container.read(chatProvider);

        check(state.messages.length).equals(2);
        check(state.messages.last).isA<ChatMessageError>();
        check(spyTalker.handleCalls).length.equals(1);
        check(spyTalker.handleCalls.first.exception).equals(expectedException);
        check(spyTalker.handleCalls.first.stackTrace).isNotNull();
      });

      test('画像付き送信: ユーザーメッセージに画像データが保持されリポジトリに渡されること', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);
        final dummyBytes = Uint8List.fromList([4, 5, 6]);

        await notifier.sendMessageStream('画像付きStream', imageBytes: dummyBytes);

        final state = container.read(chatProvider);
        final userMessage = state.messages.first as ChatMessageUser;
        check(userMessage.text).equals('画像付きStream');
        check(userMessage.imageBytes).equals(dummyBytes);
        check(fakeRepo.lastStreamImageBytes).equals(dummyBytes);
      });

      test('テキストが空でも画像があれば送信処理が実行されること', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);
        final dummyBytes = Uint8List.fromList([7, 8, 9]);

        await notifier.sendMessageStream('', imageBytes: dummyBytes);

        check(fakeRepo.sendMessageStreamCallCount).equals(1);
        final state = container.read(chatProvider);
        final userMessage = state.messages.first as ChatMessageUser;
        check(userMessage.text).equals('');
        check(userMessage.imageBytes).equals(dummyBytes);
      });

      group('Function Calling（ツール呼び出し）', () {
        test(
          '正常系: createMemo ツール呼び出し時にアクションメッセージが挿入され、AIの最終返答が反映されること',
          () async {
            final fakeRepo = FakeChatRepository()
              ..customStreamEvents = [
                const ChatStreamEvent.functionCall(
                  name: ChatActionNames.createMemo,
                  args: {CreateMemoActionKeys.title: '牛乳を買う'},
                  id: 'call-1',
                ),
              ]
              ..customFunctionResponseEvents = [
                const ChatStreamEvent.text('メモに「牛乳を買う」を追加しました！'),
              ];

            final fakeDispatcher = FakeAppActionDispatcher()
              ..responseToReturn = {
                ChatActionResultKeys.status: ChatActionResultKeys.success,
                CreateMemoActionKeys.title: '牛乳を買う',
              };

            final container = createContainer(
              fakeRepo,
              fakeDispatcher: fakeDispatcher,
            );
            final notifier = container.read(chatProvider.notifier);

            await notifier.sendMessageStream('買い物メモを作って');

            final state = container.read(chatProvider);

            // 検証:
            // 0: User ("買い物メモを作って")
            // 1: Action (createMemo, detail: "牛乳を買う", isError: false)
            // 2: AI ("メモに「牛乳を買う」を追加しました！")
            check(state.messages.length).equals(3);

            final actionMessage = state.messages[1];
            check(actionMessage).isA<ChatMessageAction>();
            final action = actionMessage as ChatMessageAction;
            check(action.actionType).equals(ChatActionType.createMemo);
            check(action.detail).equals('牛乳を買う');
            check(action.isError).isFalse();

            final aiMessage = state.messages[2];
            check(aiMessage).isA<ChatMessageAi>();
            check(
              (aiMessage as ChatMessageAi).text,
            ).equals('メモに「牛乳を買う」を追加しました！');

            // リポジトリへの呼び出し検証
            check(fakeDispatcher.executeCallCount).equals(1);
            check(
              fakeDispatcher.lastExecutedName,
            ).equals(ChatActionNames.createMemo);
            check(fakeRepo.sendFunctionResponseStreamCallCount).equals(1);
            check(fakeRepo.lastFunctionName).equals(ChatActionNames.createMemo);
            check(fakeRepo.lastFunctionId).equals('call-1');
          },
        );

        test('正常系: listMemos ツール呼び出し時に件数が detail に反映されること', () async {
          final fakeRepo = FakeChatRepository()
            ..customStreamEvents = [
              const ChatStreamEvent.functionCall(
                name: ChatActionNames.listMemos,
                args: {ListMemosActionKeys.query: 'flutter'},
              ),
            ]
            ..customFunctionResponseEvents = [
              const ChatStreamEvent.text('2件見つかりました'),
            ];

          final fakeDispatcher = FakeAppActionDispatcher()
            ..responseToReturn = {
              ChatActionResultKeys.status: ChatActionResultKeys.success,
              ListMemosActionKeys.count: 2,
            };

          final container = createContainer(
            fakeRepo,
            fakeDispatcher: fakeDispatcher,
          );
          final notifier = container.read(chatProvider.notifier);

          await notifier.sendMessageStream('メモを検索して');

          final state = container.read(chatProvider);
          check(state.messages.length).equals(3);

          final action = state.messages[1] as ChatMessageAction;
          check(action.actionType).equals(ChatActionType.listMemos);
          check(action.detail).equals('2');
          check(action.isError).isFalse();
        });

        test('正常系: changeThemeMode ツール呼び出し時にテーマ名が detail に反映されること', () async {
          final fakeRepo = FakeChatRepository()
            ..customStreamEvents = [
              const ChatStreamEvent.functionCall(
                name: ChatActionNames.changeThemeMode,
                args: {ChangeThemeActionKeys.theme: ChangeThemeActionKeys.dark},
              ),
            ]
            ..customFunctionResponseEvents = [
              const ChatStreamEvent.text('ダークモードに切り替えました'),
            ];

          final fakeDispatcher = FakeAppActionDispatcher()
            ..responseToReturn = {
              ChatActionResultKeys.status: ChatActionResultKeys.success,
              ChangeThemeActionKeys.theme: ChangeThemeActionKeys.dark,
            };

          final container = createContainer(
            fakeRepo,
            fakeDispatcher: fakeDispatcher,
          );
          final notifier = container.read(chatProvider.notifier);

          await notifier.sendMessageStream('ダークモードにして');

          final state = container.read(chatProvider);
          check(state.messages.length).equals(3);

          final action = state.messages[1] as ChatMessageAction;
          check(action.actionType).equals(ChatActionType.changeThemeMode);
          check(action.detail).equals(ChangeThemeActionKeys.dark);
          check(action.isError).isFalse();
        });

        test('正常系: createMemo ツール呼び出し時、 '
            'resultにtitleがなくてもargsからフォールバックされること', () async {
          final fakeRepo = FakeChatRepository()
            ..customStreamEvents = [
              const ChatStreamEvent.functionCall(
                name: ChatActionNames.createMemo,
                args: {CreateMemoActionKeys.title: 'フォールバックメモ'},
              ),
            ]
            ..customFunctionResponseEvents = [
              const ChatStreamEvent.text('メモを作成しました'),
            ];

          final fakeDispatcher = FakeAppActionDispatcher()
            ..responseToReturn = {
              ChatActionResultKeys.status: ChatActionResultKeys.success,
            };

          final container = createContainer(
            fakeRepo,
            fakeDispatcher: fakeDispatcher,
          );
          final notifier = container.read(chatProvider.notifier);

          await notifier.sendMessageStream('メモ作成');

          final state = container.read(chatProvider);
          final action = state.messages[1] as ChatMessageAction;
          check(action.actionType).equals(ChatActionType.createMemo);
          check(action.detail).equals('フォールバックメモ');
        });

        test('正常系: changeThemeMode ツール呼び出し時、 '
            'resultにthemeがなくてもargsからフォールバックされること', () async {
          final fakeRepo = FakeChatRepository()
            ..customStreamEvents = [
              const ChatStreamEvent.functionCall(
                name: ChatActionNames.changeThemeMode,
                args: {
                  ChangeThemeActionKeys.theme: ChangeThemeActionKeys.light,
                },
              ),
            ]
            ..customFunctionResponseEvents = [
              const ChatStreamEvent.text('ライトモードに切り替えました'),
            ];

          final fakeDispatcher = FakeAppActionDispatcher()
            ..responseToReturn = {
              ChatActionResultKeys.status: ChatActionResultKeys.success,
            };

          final container = createContainer(
            fakeRepo,
            fakeDispatcher: fakeDispatcher,
          );
          final notifier = container.read(chatProvider.notifier);

          await notifier.sendMessageStream('ライトモードにして');

          final state = container.read(chatProvider);
          final action = state.messages[1] as ChatMessageAction;
          check(action.actionType).equals(ChatActionType.changeThemeMode);
          check(action.detail).equals(ChangeThemeActionKeys.light);
        });

        test('未知のツール名の場合はアクションチップを挿入せずAI返答のみ反映されること', () async {
          final fakeRepo = FakeChatRepository()
            ..customStreamEvents = [
              const ChatStreamEvent.functionCall(
                name: 'unknownAction',
                args: {'foo': 'bar'},
              ),
            ]
            ..customFunctionResponseEvents = [
              const ChatStreamEvent.text('未知のツールを実行しました'),
            ];

          final fakeDispatcher = FakeAppActionDispatcher()
            ..responseToReturn = {
              ChatActionResultKeys.status: ChatActionResultKeys.error,
              ChatActionResultKeys.errorMessage: 'Unsupported action',
            };

          final container = createContainer(
            fakeRepo,
            fakeDispatcher: fakeDispatcher,
          );
          final notifier = container.read(chatProvider.notifier);

          await notifier.sendMessageStream('未知のツールを実行して');

          final state = container.read(chatProvider);
          // 未知のツールのため Action メッセージは入らず、User と AI の2つのみ
          check(state.messages.length).equals(2);
          check(state.messages[0]).isA<ChatMessageUser>();
          check(state.messages[1]).isA<ChatMessageAi>();
          check(
            (state.messages[1] as ChatMessageAi).text,
          ).equals('未知のツールを実行しました');
        });

        test('異常系: ツール実行が失敗（status: error）した場合、isError: true となること', () async {
          final fakeRepo = FakeChatRepository()
            ..customStreamEvents = [
              const ChatStreamEvent.functionCall(
                name: ChatActionNames.createMemo,
                args: {CreateMemoActionKeys.title: '失敗メモ'},
              ),
            ]
            ..customFunctionResponseEvents = [
              const ChatStreamEvent.text('メモの作成に失敗しました'),
            ];

          final fakeDispatcher = FakeAppActionDispatcher()
            ..responseToReturn = {
              ChatActionResultKeys.status: ChatActionResultKeys.error,
              ChatActionResultKeys.errorMessage: 'Database write error',
            };

          final container = createContainer(
            fakeRepo,
            fakeDispatcher: fakeDispatcher,
          );
          final notifier = container.read(chatProvider.notifier);

          await notifier.sendMessageStream('メモを作って');

          final state = container.read(chatProvider);
          check(state.messages.length).equals(3);

          final action = state.messages[1] as ChatMessageAction;
          check(action.actionType).equals(ChatActionType.createMemo);
          check(action.isError).isTrue();
          check(action.detail).isNull();
        });

        test(
          'Fencing: ツール実行（dispatcher.execute）中にアカウント切り替えがあった場合、状態更新が遮断されること',
          () async {
            final fakeRepo = FakeChatRepository()
              ..customStreamEvents = [
                const ChatStreamEvent.functionCall(
                  name: ChatActionNames.createMemo,
                  args: {CreateMemoActionKeys.title: '切り替えメモ'},
                ),
              ];

            late ProviderContainer container;
            final fakeDispatcher = FakeAppActionDispatcher()
              ..onExecute = () async {
                // ツール実行の瞬間にアカウント切り替え
                container.read(testUserIdProvider.notifier).userId =
                    'user-changed';
              };

            container = createContainer(
              fakeRepo,
              fakeDispatcher: fakeDispatcher,
            );
            final notifier = container.read(chatProvider.notifier);

            await notifier.sendMessageStream('メモを作って');

            // 検証: clearHistoryによりメッセージは空になり、古いリクエストの更新は遮断されていること
            final state = container.read(chatProvider);
            check(state.messages).isEmpty();
            check(state.isGenerating).isFalse();
            check(fakeRepo.sendFunctionResponseStreamCallCount).equals(0);
          },
        );

        test(
          'Fencing: sendFunctionResponseStream 受信中にアカウント切り替えがあった場合、更新が遮断されること',
          () async {
            final fakeRepo = FakeChatRepository()
              ..customStreamEvents = [
                const ChatStreamEvent.functionCall(
                  name: ChatActionNames.createMemo,
                  args: {CreateMemoActionKeys.title: 'メモ'},
                ),
              ];

            final fakeDispatcher = FakeAppActionDispatcher();
            final container = createContainer(
              fakeRepo,
              fakeDispatcher: fakeDispatcher,
            );
            final notifier = container.read(chatProvider.notifier);

            final future = notifier.sendMessageStream('メモを作って');

            // ツール実行完了直後のストリーム受信中にアカウント切り替え
            await Future<void>.delayed(const Duration(milliseconds: 25));
            container.read(testUserIdProvider.notifier).userId =
                'user-changed-2';

            await future;

            final state = container.read(chatProvider);
            check(state.messages).isEmpty();
            check(state.isGenerating).isFalse();
          },
        );

        test('正常系: 並列関数呼び出し（複数のツール要求）を同時に受信した場合、 '
            'すべて実行して結果をまとめて返送すること', () async {
          final fakeRepo = FakeChatRepository()
            ..customStreamEvents = [
              const ChatStreamEvent.functionCall(
                name: ChatActionNames.createMemo,
                args: {CreateMemoActionKeys.title: '並列メモ'},
                id: 'call_memo',
              ),
              const ChatStreamEvent.functionCall(
                name: ChatActionNames.changeThemeMode,
                args: {ChangeThemeActionKeys.theme: ChangeThemeActionKeys.dark},
                id: 'call_theme',
              ),
            ]
            ..customFunctionResponseEvents = [
              const ChatStreamEvent.text('メモを作成し、ダークモードにしました！'),
            ];

          final executedCalls = <String>[];
          final fakeDispatcher = FakeAppActionDispatcher()
            ..onExecute = () async {
              executedCalls.add('executed');
            };

          final container = createContainer(
            fakeRepo,
            fakeDispatcher: fakeDispatcher,
          );
          final notifier = container.read(chatProvider.notifier);

          await notifier.sendMessageStream('メモを作ってダークモードにして');

          // 1. dispatcher が2回呼ばれたこと
          check(fakeDispatcher.executeCallCount).equals(2);

          // 2. 状態メッセージに2つのアクションチップとAI返答が含まれていること
          final state = container.read(chatProvider);
          // messages: [user, action1, action2, ai]
          check(state.messages.length).equals(4);

          final action1 = state.messages[1] as ChatMessageAction;
          check(action1.actionType).equals(ChatActionType.createMemo);
          check(action1.detail).equals('並列メモ');

          final action2 = state.messages[2] as ChatMessageAction;
          check(action2.actionType).equals(ChatActionType.changeThemeMode);
          check(action2.detail).equals(ChangeThemeActionKeys.dark);

          final aiMsg = state.messages[3] as ChatMessageAi;
          check(aiMsg.text).equals('メモを作成し、ダークモードにしました！');

          // 3. sendFunctionResponseStream に2つのレスポンスがまとめて渡されたこと
          check(fakeRepo.sendFunctionResponseStreamCallCount).equals(1);
          check(fakeRepo.lastFunctionResponses?.length).equals(2);
          check(
            fakeRepo.lastFunctionResponses?[0].name,
          ).equals(ChatActionNames.createMemo);
          check(fakeRepo.lastFunctionResponses?[0].id).equals('call_memo');
          check(
            fakeRepo.lastFunctionResponses?[1].name,
          ).equals(ChatActionNames.changeThemeMode);
          check(fakeRepo.lastFunctionResponses?[1].id).equals('call_theme');
        });

        test('安全装置: 最大ターン数（maxTurns = 3）に達した場合はループが終了すること', () async {
          final fakeRepo = FakeChatRepository()
            ..customStreamEvents = [
              const ChatStreamEvent.functionCall(
                name: ChatActionNames.listMemos,
                args: {},
              ),
            ]
            ..multiTurnFunctionResponseEvents = [
              // ターン1の応答 -> 2回目のfunctionCall
              [
                const ChatStreamEvent.functionCall(
                  name: ChatActionNames.listMemos,
                  args: {},
                ),
              ],
              // ターン2の応答 -> 3回目のfunctionCall
              [
                const ChatStreamEvent.functionCall(
                  name: ChatActionNames.listMemos,
                  args: {},
                ),
              ],
              // ターン3の応答 -> 4回目を要求してもmaxTurns=3でループ終了する
              [
                const ChatStreamEvent.functionCall(
                  name: ChatActionNames.listMemos,
                  args: {},
                ),
              ],
            ];

          final fakeDispatcher = FakeAppActionDispatcher()
            ..responseToReturn = {
              ChatActionResultKeys.status: ChatActionResultKeys.success,
              ListMemosActionKeys.count: 1,
            };

          final container = createContainer(
            fakeRepo,
            fakeDispatcher: fakeDispatcher,
          );
          final notifier = container.read(chatProvider.notifier);

          await notifier.sendMessageStream('無限ループテスト');

          // execute は最大3回まで呼ばれること
          check(fakeDispatcher.executeCallCount).equals(3);
          // 1回目と2回目は結果返送ストリームが生成され、3回目は上限に達して返送せずループ終了すること
          check(fakeRepo.sendFunctionResponseStreamCallCount).equals(2);
        });
      });
    });

    test('clearHistory: 履歴が削除され初期状態に戻ること', () async {
      final fakeRepo = FakeChatRepository();
      final container = createContainer(fakeRepo);
      final notifier = container.read(chatProvider.notifier);

      // まずメッセージを1つ追加
      await notifier.sendMessage('テスト');
      check(container.read(chatProvider).messages).isNotEmpty();

      // クリア実行
      notifier.clearHistory();

      final state = container.read(chatProvider);
      check(state.messages).isEmpty();
      check(state.isGenerating).equals(false);
    });

    test(
      'dispose 後の非同期例外でも Talker.handle が呼ばれ、かつクラッシュしないこと (sendMessage)',
      () async {
        final expectedException = Exception('Dispose API Error');
        final fakeRepo = FakeChatRepository()
          ..exceptionToThrow = expectedException;
        final spy = SpyTalker();
        final container = ProviderContainer(
          overrides: [
            chatRepositoryProvider.overrideWithValue(fakeRepo),
            clockProvider.overrideWithValue(DateTime.now),
            uuidProvider.overrideWithValue(FakeUuid()),
            loggerProvider.overrideWithValue(spy),
          ],
        );

        final notifier = container.read(chatProvider.notifier);
        final future = notifier.sendMessage('disposeテスト');
        container.dispose();
        await future;

        check(spy.handleCalls).length.equals(1);
        check(spy.handleCalls.first.exception).equals(expectedException);
        check(spy.handleCalls.first.stackTrace).isNotNull();
      },
    );

    test(
      'dispose 後の非同期例外でも Talker.handle が呼ばれ、かつクラッシュしないこと (sendMessageStream)',
      () async {
        final expectedException = Exception('Dispose Stream API Error');
        final fakeRepo = FakeChatRepository()
          ..streamExceptionToThrow = expectedException;
        final spy = SpyTalker();
        final container = ProviderContainer(
          overrides: [
            chatRepositoryProvider.overrideWithValue(fakeRepo),
            clockProvider.overrideWithValue(DateTime.now),
            uuidProvider.overrideWithValue(FakeUuid()),
            loggerProvider.overrideWithValue(spy),
          ],
        );

        final notifier = container.read(chatProvider.notifier);
        final future = notifier.sendMessageStream('disposeストリームテスト');
        container.dispose();
        await future;

        check(spy.handleCalls).length.equals(1);
        check(spy.handleCalls.first.exception).equals(expectedException);
        check(spy.handleCalls.first.stackTrace).isNotNull();
      },
    );

    group('認証状態の変更・サインアウト連動 (Issue #311)', () {
      test('ユーザーID変更時（アカウント切り替え）に履歴が自動クリアされ、セッションが破棄されること', () async {
        var repoDisposed = false;
        final fakeRepo = FakeChatRepository();
        final container = createContainer(
          fakeRepo,
          onRepoInit: (ref) {
            ref.onDispose(() => repoDisposed = true);
          },
        );
        final notifier = container.read(chatProvider.notifier);

        // メッセージを送信して履歴を作る
        await notifier.sendMessage('アカウントAのメッセージ');
        check(container.read(chatProvider).messages).isNotEmpty();
        check(repoDisposed).isFalse();

        // ユーザーIDを変更（アカウント切り替え）
        container.read(testUserIdProvider.notifier).userId = 'user-b';

        // 検証: 履歴が空になり、chatRepositoryProviderが破棄されていること
        final state = container.read(chatProvider);
        check(state.messages).isEmpty();
        check(state.isGenerating).isFalse();
        check(repoDisposed).isTrue();
      });

      test(
        'サインアウト時（isAuthenticatedがfalseへ遷移）に履歴が自動クリアされ、セッションが破棄されること',
        () async {
          var repoDisposed = false;
          final fakeRepo = FakeChatRepository();
          final container = createContainer(
            fakeRepo,
            onRepoInit: (ref) {
              ref.onDispose(() => repoDisposed = true);
            },
          );
          final notifier = container.read(chatProvider.notifier);

          await notifier.sendMessage('ログアウト前のメッセージ');
          check(container.read(chatProvider).messages).isNotEmpty();
          check(repoDisposed).isFalse();

          // ログアウト状態へ遷移
          container.read(testAuthNotifierProvider.notifier).isAuthenticated =
              false;

          final state = container.read(chatProvider);
          check(state.messages).isEmpty();
          check(state.isGenerating).isFalse();
          check(repoDisposed).isTrue();
        },
      );

      test(
        '自前認証ログイン時（isAuthenticatedがtrueへ遷移）に未ログイン時の履歴が自動クリアされ、セッションが破棄されること',
        () async {
          var repoDisposed = false;
          final fakeRepo = FakeChatRepository();
          final container = createContainer(
            fakeRepo,
            onRepoInit: (ref) {
              ref.onDispose(() => repoDisposed = true);
            },
          );
          // 未ログイン状態を設定
          container.read(testAuthNotifierProvider.notifier).isAuthenticated =
              false;
          repoDisposed = false;

          final notifier = container.read(chatProvider.notifier);
          await notifier.sendMessage('未ログイン時のメッセージ');
          check(container.read(chatProvider).messages).isNotEmpty();
          check(repoDisposed).isFalse();

          // ログイン状態へ遷移（未ログイン時の履歴が漏洩しないようリセット）
          container.read(testAuthNotifierProvider.notifier).isAuthenticated =
              true;

          final state = container.read(chatProvider);
          check(state.messages).isEmpty();
          check(state.isGenerating).isFalse();
          check(repoDisposed).isTrue();
        },
      );

      test('サインアウト時（currentUserIdがnullへ遷移）に履歴が自動クリアされ、セッションが破棄されること', () async {
        var repoDisposed = false;
        final fakeRepo = FakeChatRepository();
        final container = createContainer(
          fakeRepo,
          onRepoInit: (ref) {
            ref.onDispose(() => repoDisposed = true);
          },
        );
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessage('Firebaseログアウト前のメッセージ');
        check(container.read(chatProvider).messages).isNotEmpty();

        // Firebaseログアウト（nullへ遷移）
        container.read(testUserIdProvider.notifier).userId = null;

        final state = container.read(chatProvider);
        check(state.messages).isEmpty();
        check(state.isGenerating).isFalse();
        check(repoDisposed).isTrue();
      });

      test(
        'sendMessage送信中にサインアウトされた場合、返答がstateに反映されず遮断（Fencing）されること',
        () async {
          final fakeRepo = FakeChatRepository();
          final container = createContainer(fakeRepo);
          final notifier = container.read(chatProvider.notifier);

          // 送信開始（50ms待機中にログアウトさせる）
          final future = notifier.sendMessage('送信中の質問');

          check(container.read(chatProvider).isGenerating).isTrue();

          // 通信中にログアウト
          container.read(testAuthNotifierProvider.notifier).isAuthenticated =
              false;

          await future;

          // 検証: ログアウト後の画面に古いレスポンスは反映されず、isGeneratingも解除されていること
          final state = container.read(chatProvider);
          check(state.messages).isEmpty();
          check(state.isGenerating).isFalse();
        },
      );

      test(
        'sendMessageStream受信中にアカウントが切り替わった場合、後続チャンクが遮断（Fencing）されること',
        () async {
          final fakeRepo = FakeChatRepository();
          final container = createContainer(fakeRepo);
          final notifier = container.read(chatProvider.notifier);

          // Stream送信開始
          final future = notifier.sendMessageStream('ストリーミング質問');

          check(container.read(chatProvider).isGenerating).isTrue();

          // 最初のチャンクが流れる直前にアカウント切り替え
          container.read(testUserIdProvider.notifier).userId = 'user-new';

          await future;

          // 検証: 履歴は空のままであり、新アカウントに古いストリームデータが混入していないこと
          final state = container.read(chatProvider);
          check(state.messages).isEmpty();
          check(state.isGenerating).isFalse();
        },
      );

      test('sendMessage送信中に例外が発生し、世代が変更されていた場合エラー表示も遮断されること', () async {
        final expectedException = Exception('API Error');
        final fakeRepo = FakeChatRepository()
          ..exceptionToThrow = expectedException;
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        final future = notifier.sendMessage('エラー質問');
        container.read(testUserIdProvider.notifier).userId = 'user-changed';

        await future;

        final state = container.read(chatProvider);
        check(state.messages).isEmpty();
        check(state.isGenerating).isFalse();
      });

      test('sendMessageStream受信中に例外が発生し、世代が変更されていた場合エラー表示も遮断されること', () async {
        final expectedException = Exception('Stream API Error');
        final fakeRepo = FakeChatRepository()
          ..streamExceptionToThrow = expectedException;
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        final future = notifier.sendMessageStream('Streamエラー質問');
        container.read(testUserIdProvider.notifier).userId = 'user-changed';

        await future;

        final state = container.read(chatProvider);
        check(state.messages).isEmpty();
        check(state.isGenerating).isFalse();
      });

      test(
        'clearHistory手動呼び出し時にchatRepositoryProviderが無効化（再生成）されること',
        () async {
          var repoDisposed = false;
          final fakeRepo = FakeChatRepository();
          final container = createContainer(
            fakeRepo,
            onRepoInit: (ref) {
              ref.onDispose(() => repoDisposed = true);
            },
          );
          final notifier = container.read(chatProvider.notifier);

          await notifier.sendMessage('テスト');
          check(repoDisposed).isFalse();

          notifier.clearHistory();

          check(repoDisposed).isTrue();
          check(container.read(chatProvider).messages).isEmpty();
        },
      );
    });
  });
}
