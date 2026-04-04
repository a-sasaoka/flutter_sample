import 'dart:async';

import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/features/chat/application/chat_notifier.dart';
import 'package:flutter_sample/src/features/chat/data/chat_provider.dart';
import 'package:flutter_sample/src/features/chat/data/chat_repository.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// --- Fake Repository ---
// Streamの挙動を完全にコントロールするためのFakeクラス
class FakeChatRepository extends Fake implements ChatRepository {
  bool shouldThrow = false;
  bool shouldStreamThrow = false;
  bool streamEmpty = false;

  // Streamで流す分割された文字列（チャンク）
  List<String> streamChunks = ['AI', 'からの', '返答です'];

  // Streamに渡された最終的なテキスト（日時コンテキスト検証用）
  String? lastStreamText;

  @override
  Future<String> sendMessage(String text) async {
    if (shouldThrow) throw Exception('API Error');
    return '単発のAI返答';
  }

  @override
  Stream<String> sendMessageStream(String text) async* {
    lastStreamText = text;

    if (shouldStreamThrow) throw Exception('Stream API Error');
    if (streamEmpty) return; // 空のStreamを返して終了

    for (final chunk in streamChunks) {
      // Streamが徐々に流れてくる様子をシミュレート
      await Future<void>.delayed(const Duration(milliseconds: 1));
      yield chunk;
    }
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
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ChatNotifier', () {
    test('初期化: build() は空のリストを返すこと', () {
      final fakeRepo = FakeChatRepository();
      final container = createContainer(fakeRepo);

      final state = container.read(chatProvider);

      expect(state, isEmpty);
    });

    group('sendMessage (単発送信)', () {
      test('空文字の場合は何もしないこと', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessage('   '); // スペースのみ

        expect(container.read(chatProvider), isEmpty);
      });

      test('正常系: ユーザーのメッセージとAIの返答がstateに追加されること', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessage('こんにちは');

        final state = container.read(chatProvider);

        expect(state.length, 2);
        expect(state.first, isA<ChatMessageUser>());
        expect(state.first.toString(), contains('こんにちは'));

        expect(state.last, isA<ChatMessageAi>());
        expect(state.last.toString(), contains('単発のAI返答'));
      });

      test('異常系: 例外が発生した場合、最後の要素がエラーメッセージに差し替わること', () async {
        final fakeRepo = FakeChatRepository()..shouldThrow = true;
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessage('こんにちは');

        final state = container.read(chatProvider);

        expect(state.length, 2);
        expect(state.last, isA<ChatMessageError>());
      });
    });

    group('sendMessageStream (Stream送信)', () {
      test('空文字の場合は何もしないこと', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessageStream('   ');

        expect(container.read(chatProvider), isEmpty);
      });

      test('正常系: システム日時が付与され、Streamから届くチャンクが結合されていくこと', () async {
        final fakeRepo = FakeChatRepository();
        final container = createContainer(fakeRepo)
          ..listen(chatProvider, (_, _) {});

        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessageStream('ストリームテスト');

        final state = container.read(chatProvider);

        // 1. 結合されたメッセージの検証
        expect(state.length, 2);
        expect(state.last, isA<ChatMessageAi>());
        expect(state.last.toString(), contains('AIからの返答です'));

        // 2. 日付コンテキスト（システム情報）が正しく Repository に渡されたかの検証
        expect(
          fakeRepo.lastStreamText,
          '（※システム情報: 現在時刻は 2026年3月21日 10時0分 です）\nストリームテスト',
        );
      });

      test(
        '異常系: Stream が空っぽで終わった場合、ChatEmptyResponseException としてエラー表示になること',
        () async {
          final fakeRepo = FakeChatRepository()..streamEmpty = true;
          final container = createContainer(fakeRepo);
          final notifier = container.read(chatProvider.notifier);

          await notifier.sendMessageStream('空のStream');

          final state = container.read(chatProvider);

          expect(state.length, 2);
          expect(state.last, isA<ChatMessageError>());
          expect(state.last.toString(), contains('ChatEmptyResponseException'));
        },
      );

      test('異常系: Stream の途中で例外が発生した場合、エラー表示になること', () async {
        final fakeRepo = FakeChatRepository()..shouldStreamThrow = true;
        final container = createContainer(fakeRepo);
        final notifier = container.read(chatProvider.notifier);

        await notifier.sendMessageStream('エラーが起きるStream');

        final state = container.read(chatProvider);

        expect(state.length, 2);
        expect(state.last, isA<ChatMessageError>());
      });
    });
  });
}
