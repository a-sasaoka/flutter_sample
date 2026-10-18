import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_stream_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatStreamEvent テスト', () {
    test('text: テキストチャンクのプロパティが正しく保持されること', () {
      const event = ChatStreamEvent.text('こんにちは');

      check(event).isA<ChatStreamEventText>();
      const textEvent = event as ChatStreamEventText;
      check(textEvent.text).equals('こんにちは');
    });

    test('functionCall: ツール呼び出し要求のプロパティが正しく保持されること', () {
      const event = ChatStreamEvent.functionCall(
        name: 'createMemo',
        args: {'title': '買い物', 'content': '牛乳'},
        id: 'call_123',
      );

      check(event).isA<ChatStreamEventFunctionCall>();
      const callEvent = event as ChatStreamEventFunctionCall;
      check(callEvent.name).equals('createMemo');
      check(callEvent.args).deepEquals({'title': '買い物', 'content': '牛乳'});
      check(callEvent.id).equals('call_123');
    });

    test('同値性(Equatable): 同じプロパティを持つインスタンスは等価と判定されること', () {
      const event1 = ChatStreamEvent.text('テスト');
      const event2 = ChatStreamEvent.text('テスト');
      check(event1).equals(event2);

      const call1 = ChatStreamEvent.functionCall(name: 'listMemos', args: {});
      const call2 = ChatStreamEvent.functionCall(name: 'listMemos', args: {});
      check(call1).equals(call2);
    });
  });
}
