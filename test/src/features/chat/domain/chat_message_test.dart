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
      expect(message.id, 'user_1');
      expect(message.createdAt, dummyTime);

      // 2. カスタムゲッターの検証
      expect(message.isUser, isTrue);
      expect(message.isAi, isFalse);
      expect(message.displayText, 'こんにちは');
    });

    test('ai: プロパティとカスタムゲッターが正しく機能すること', () {
      final message = ChatMessage.ai(
        id: 'ai_1',
        text: 'AIの返答です',
        createdAt: dummyTime,
      );

      expect(message.id, 'ai_1');
      expect(message.createdAt, dummyTime);

      expect(message.isUser, isFalse);
      expect(message.isAi, isTrue);
      expect(message.displayText, 'AIの返答です');
    });

    test('loading: プロパティとカスタムゲッターが正しく機能すること', () {
      final message = ChatMessage.loading(
        id: 'loading_1',
        createdAt: dummyTime,
      );

      expect(message.id, 'loading_1');
      expect(message.createdAt, dummyTime);

      // loading はどちらでもなく、表示すべきテキストもない
      expect(message.isUser, isFalse);
      expect(message.isAi, isFalse);
      expect(message.displayText, isNull);
    });

    test('error: プロパティとカスタムゲッターが正しく機能すること', () {
      final exception = Exception('通信エラー');
      final message = ChatMessage.error(
        id: 'error_1',
        error: exception,
        createdAt: dummyTime,
      );

      expect(message.id, 'error_1');
      expect(message.createdAt, dummyTime);

      // error プロパティに正しくアクセスできるか（キャストして検証）
      expect((message as ChatMessageError).error, exception);

      expect(message.isUser, isFalse);
      expect(message.isAi, isFalse);
      expect(message.displayText, isNull);
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

      expect(message1, equals(message2));
      expect(message1, isNot(equals(message3)));
    });
  });
}
