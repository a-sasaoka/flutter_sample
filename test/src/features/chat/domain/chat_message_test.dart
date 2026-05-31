import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatMessage', () {
    // テスト用の共通日時
    final dummyTime = DateTime(2026, 4, 4, 14, 5);

    test('user: プロパティとカスタムゲッターが正しく機能すること', () {
      final message = ChatMessage.user(
        id: 'user_1',
        text: 'こんにちは',
        createdAt: dummyTime,
      );

      // 1. プロパティの保持確認
      check(message.id).equals('user_1');
      check(message.createdAt).equals(dummyTime);

      // 2. カスタムゲッターの検証
      check(message.isUser).equals(true);
      check(message.isAi).equals(false);
      check(message.displayText).equals('こんにちは');
    });

    test('ai: プロパティとカスタムゲッターが正しく機能すること', () {
      final message = ChatMessage.ai(
        id: 'ai_1',
        text: 'AIの返答です',
        createdAt: dummyTime,
      );

      check(message.id).equals('ai_1');
      check(message.createdAt).equals(dummyTime);

      check(message.isUser).equals(false);
      check(message.isAi).equals(true);
      check(message.displayText).equals('AIの返答です');
    });

    test('loading: プロパティとカスタムゲッターが正しく機能すること', () {
      final message = ChatMessage.loading(
        id: 'loading_1',
        createdAt: dummyTime,
      );

      check(message.id).equals('loading_1');
      check(message.createdAt).equals(dummyTime);

      // loading はどちらでもなく、表示すべきテキストもない
      check(message.isUser).equals(false);
      check(message.isAi).equals(false);
      check(message.displayText).isNull();
    });

    test('error: プロパティとカスタムゲッターが正しく機能すること', () {
      final exception = Exception('通信エラー');
      final message = ChatMessage.error(
        id: 'error_1',
        error: exception,
        createdAt: dummyTime,
      );

      check(message.id).equals('error_1');
      check(message.createdAt).equals(dummyTime);

      // error プロパティに正しくアクセスできるか（キャストして検証）
      check((message as ChatMessageError).error).equals(exception);

      check(message.isUser).equals(false);
      check(message.isAi).equals(false);
      check(message.displayText).isNull();
    });

    test('同値性(Equatable): 同じ値を持つインスタンスは等価と判定されること', () {
      // Freezedの機能により、値が全く同じなら == で true になることを確認
      final message1 = ChatMessage.user(
        id: '1',
        text: 'テスト',
        createdAt: dummyTime,
      );
      final message2 = ChatMessage.user(
        id: '1',
        text: 'テスト',
        createdAt: dummyTime,
      );
      final message3 = ChatMessage.user(
        id: '2', // 💡 IDだけが違う
        text: 'テスト',
        createdAt: dummyTime,
      );

      check(message1).equals(message2);
      check(message1).not((it) => it.equals(message3));
    });
  });
}
