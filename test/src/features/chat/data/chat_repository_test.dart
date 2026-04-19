import 'dart:async';

import 'package:flutter_sample/src/features/chat/data/chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChatApiClient extends Mock implements ChatApiClient {}

void main() {
  group('ChatRepository', () {
    late MockChatApiClient mockApiClient;
    late ChatRepository repository;

    setUp(() {
      mockApiClient = MockChatApiClient();
      // テスト用の（偽物の）APIクライアントを注入
      repository = ChatRepository(
        now: DateTime(2026, 3, 21, 10),
        apiClient: mockApiClient,
      );
    });

    group('sendMessage (単発送信)', () {
      test('正常系: AIからのテキストが返ること', () async {
        when(
          () => mockApiClient.sendMessage(any()),
        ).thenAnswer((_) async => 'AIの返答です');

        final result = await repository.sendMessage('こんにちは');

        expect(result, 'AIの返答です');
        verify(() => mockApiClient.sendMessage('こんにちは')).called(1);
      });

      test(
        '異常系: APIから null が返った場合、ChatEmptyResponseException を投げること',
        () async {
          when(
            () => mockApiClient.sendMessage(any()),
          ).thenAnswer((_) async => null); // nullを返す

          expect(
            () => repository.sendMessage('こんにちは'),
            throwsA(isA<ChatEmptyResponseException>()),
          );
        },
      );

      test('異常系: APIから 空文字 が返った場合、ChatEmptyResponseException を投げること', () async {
        when(
          () => mockApiClient.sendMessage(any()),
        ).thenAnswer((_) async => ''); // 空文字を返す

        expect(
          () => repository.sendMessage('こんにちは'),
          throwsA(isA<ChatEmptyResponseException>()),
        );
      });
    });

    group('sendMessageStream (Stream送信)', () {
      test('正常系: チャンクからテキストが抽出されてStreamで流れること', () async {
        when(
          () => mockApiClient.sendMessageStream(any()),
        ).thenAnswer((_) => Stream.fromIterable(['AI', 'からの返答']));

        final stream = repository.sendMessageStream('こんにちは');

        expect(stream, emitsInOrder(['AI', 'からの返答']));
      });

      test('正常系: チャンクのテキストがnullの場合は空文字に変換されて流れること', () async {
        // null が混ざったStreamを返す
        when(
          () => mockApiClient.sendMessageStream(any()),
        ).thenAnswer((_) => Stream.fromIterable(['AI', null, 'です']));

        final stream = repository.sendMessageStream('こんにちは');

        // chunk ?? '' のロジックにより、null が '' に変換されるはず
        expect(stream, emitsInOrder(['AI', '', 'です']));
      });
    });
  });
}
