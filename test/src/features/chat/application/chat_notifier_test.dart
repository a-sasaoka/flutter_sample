import 'dart:async';

import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/uuid_provider.dart';
import 'package:flutter_sample/src/features/chat/application/chat_notifier.dart';
import 'package:flutter_sample/src/features/chat/data/chat_provider.dart';
import 'package:flutter_sample/src/features/chat/data/chat_repository.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

// --- Fake Repository ---
// Streamの挙動を完全にコントロールするためのFakeクラス
class FakeChatRepository extends Fake implements ChatRepository {
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

  @override
  Future<String> sendMessage(String text) async {
    sendMessageCallCount++;
    if (shouldThrow) throw Exception('API Error');
    // 非同期処理（生成中）をシミュレートするため少し待つ
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return '単発のAI返答';
  }

  @override
  Stream<String> sendMessageStream(String text) async* {
    sendMessageStreamCallCount++;
    lastStreamText = text;

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

void main() {
  /// テスト環境のセットアップヘルパー
  ProviderContainer createContainer(FakeChatRepository fakeRepo) {
    // 現在時刻を固定して、システム情報の文字列を完全に予測可能にする
    final fixedDateTime = DateTime(2026, 3, 21, 10);

    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(fakeRepo),
        currentDateTimeProvider.overrideWithValue(fixedDateTime),
        uuidProvider.overrideWithValue(FakeUuid()),
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

      expect(state.messages, isEmpty);
    });

    group('sendMessage (単発送信)', () {
      test('空文字の場合は何もしないこと', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessage('   '); // スペースのみ

        expect(container.read(chatProvider).messages, isEmpty);
        expect(fakeRepo.sendMessageCallCount, 0); // 呼ばれていないこと
      });

      test('正常系: ユーザーのメッセージとAIの返答がstateに追加されること', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessage('こんにちは');

        final state = container.read(chatProvider);

        expect(state.messages.length, 2);
        expect(state.messages.first, isA<ChatMessageUser>());
        expect(state.messages.first.toString(), contains('こんにちは'));

        expect(state.messages.last, isA<ChatMessageAi>());
        expect(state.messages.last.toString(), contains('単発のAI返答'));
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
        expect(fakeRepo.sendMessageCallCount, 1);
        expect(state.messages.length, 2);
        expect(state.messages.first.toString(), contains('1回目'));
      });

      test('異常系: 例外が発生した場合、対象の要素がエラーメッセージに差し替わること', () async {
        final fakeRepo = FakeChatRepository()..shouldThrow = true;
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessage('こんにちは');

        final state = container.read(chatProvider);

        expect(state.messages.length, 2);
        expect(state.messages.last, isA<ChatMessageError>());
      });
    });

    group('sendMessageStream (Stream送信)', () {
      test('空文字の場合は何もしないこと', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessageStream('   ');

        expect(container.read(chatProvider).messages, isEmpty);
        expect(fakeRepo.sendMessageStreamCallCount, 0);
      });

      test('正常系: システム日時が付与され、Streamから届くチャンクが結合されていくこと', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo)
          ..listen(chatProvider, (_, _) {});

        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessageStream('ストリームテスト');

        final state = container.read(chatProvider);

        // 1. 結合されたメッセージの検証
        expect(state.messages.length, 2);
        expect(state.messages.last, isA<ChatMessageAi>());
        expect(state.messages.last.toString(), contains('AIからの返答です'));

        // 2. 日付コンテキスト（システム情報）が正しく Repository に渡されたかの検証
        expect(
          fakeRepo.lastStreamText,
          '[System Information: Current Time is 2026-03-21 10:00]\nストリームテスト',
        );
      });

      test('排他制御: Stream生成中に連続で送信しても、2回目以降は無視されること', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        // 1回目を await せずに実行
        final future1 = notifier.sendMessageStream('1回目のStream');

        expect(
          container.read(chatProvider).isGenerating,
          isTrue,
        ); // 生成中になっていること

        // 瞬時に2回目を実行（ブロックされるはず）
        final future2 = notifier.sendMessageStream('2回目のStream');

        // 両方の完了を待つ
        await Future.wait([future1, future2]);

        final state = container.read(chatProvider);

        expect(state.isGenerating, isFalse); // 生成が終わっていること
        expect(fakeRepo.sendMessageStreamCallCount, 1);
        expect(state.messages.length, 2);
      });

      test(
        '異常系: Stream が空っぽで終わった場合、ChatEmptyResponseException としてエラー表示になること',
        () async {
          final fakeRepo = FakeChatRepository()..streamEmpty = true;
          final container = createContainer(fakeRepo);
          final notifier = container.read(chatProvider.notifier);

          await notifier.sendMessageStream('空のStream');

          final state = container.read(chatProvider);

          expect(state.messages.length, 2);
          expect(state.messages.last, isA<ChatMessageError>());
          expect(
            state.messages.last.toString(),
            contains('ChatEmptyResponseException'),
          );
        },
      );

      test('異常系: Stream の途中で例外が発生した場合、対象要素がエラー表示になること', () async {
        final fakeRepo = FakeChatRepository()..shouldStreamThrow = true;
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessageStream('エラーが起きるStream');

        final state = container.read(chatProvider);

        expect(state.messages.length, 2);
        expect(state.messages.last, isA<ChatMessageError>());
      });
    });
  });
}
