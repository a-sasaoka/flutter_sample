import 'dart:async';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/uuid_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/chat/application/chat_notifier.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';
import 'package:flutter_sample/src/features/chat/data/chat_provider.dart';
import 'package:flutter_sample/src/features/chat/data/chat_repository.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
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

  // Streamで流す分割された文字列（チャンク）
  List<String> streamChunks = ['AI', 'からの', '返答です'];

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
  Stream<String> sendMessageStream(
    String text, {
    Uint8List? imageBytes,
  }) async* {
    sendMessageStreamCallCount++;
    lastStreamText = text;
    lastStreamImageBytes = imageBytes;

    if (streamExceptionToThrow != null) throw streamExceptionToThrow!;
    if (shouldStreamThrow) throw Exception('Stream API Error');
    if (streamEmpty) return; // 空のStreamを返して終了

    for (final chunk in streamChunks) {
      // Streamが徐々に流れてくる様子をシミュレート（生成中の隙間を作る）
      await Future<void>.delayed(const Duration(milliseconds: 20));
      yield chunk;
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
