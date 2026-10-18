import 'dart:async';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';
import 'package:flutter_sample/src/features/chat/data/chat_repository.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_stream_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_checks/legacy_checks.dart';
import 'package:mocktail/mocktail.dart';

// --- モッククラスの定義 ---
class MockChatApiClient extends Mock implements ChatApiClient {}

void main() {
  late MockChatApiClient mockApiClient;
  late ChatRepository repository;

  setUp(() {
    mockApiClient = MockChatApiClient();

    repository = ChatRepository(apiClient: mockApiClient);
  });

  group('ChatRepository', () {
    group('sendMessage (単発メッセージ)', () {
      test('正常系: AIからの返答がそのまま返されること', () async {
        // Arrange: モックが返す値を設定
        when(
          () => mockApiClient.sendMessage('テストプロンプト'),
        ).thenAnswer((_) async => 'こんにちは！AIです。');

        // Act: テスト対象のメソッドを実行
        final result = await repository.sendMessage('テストプロンプト');

        // Assert: 結果を検証
        check(result).equals('こんにちは！AIです。');
        verify(() => mockApiClient.sendMessage('テストプロンプト')).called(1);
      });

      test('正常系: 画像データ付きで送信した場合、APIクライアントに画像データが渡されること', () async {
        final dummyBytes = Uint8List.fromList([1, 2, 3]);
        when(
          () => mockApiClient.sendMessage('テスト', imageBytes: dummyBytes),
        ).thenAnswer((_) async => '画像認識結果');

        final result = await repository.sendMessage(
          'テスト',
          imageBytes: dummyBytes,
        );

        check(result).equals('画像認識結果');
        verify(
          () => mockApiClient.sendMessage('テスト', imageBytes: dummyBytes),
        ).called(1);
      });

      test(
        '異常系: AIからの返答が空文字("")の場合、ChatEmptyResponseExceptionを投げること',
        () async {
          when(
            () => mockApiClient.sendMessage(any()),
          ).thenAnswer((_) async => '');

          // 例外が投げられることを検証
          await check(
            repository.sendMessage('テスト'),
          ).throws<ChatEmptyResponseException>();
        },
      );

      test('異常系: AIからの返答がnullの場合、ChatEmptyResponseExceptionを投げること', () async {
        when(
          () => mockApiClient.sendMessage(any()),
        ).thenAnswer((_) async => null);

        // nullの場合も同様に例外になることを検証
        await check(
          repository.sendMessage('テスト'),
        ).throws<ChatEmptyResponseException>();
      });
    });

    group('sendMessageStream (ストリーム)', () {
      test('正常系: Streamの各ChatStreamEventが順番に返されること', () async {
        final expectedEvents = [
          const ChatStreamEvent.text('AI'),
          const ChatStreamEvent.functionCall(
            name: 'createMemo',
            args: {'title': '買い物'},
            id: 'call_1',
          ),
          const ChatStreamEvent.text('完了'),
        ];

        when(
          () => mockApiClient.sendMessageStream('ストリームテスト'),
        ).thenAnswer((_) => Stream.fromIterable(expectedEvents));

        final stream = repository.sendMessageStream('ストリームテスト');

        check(
          stream,
        ).legacyMatcher(emitsInOrder([...expectedEvents, emitsDone]));
      });

      test('正常系: 画像データ付きでStream送信した場合、APIクライアントに画像データが渡されること', () async {
        final dummyBytes = Uint8List.fromList([4, 5, 6]);
        const expectedEvent = ChatStreamEvent.text('結果');

        when(
          () => mockApiClient.sendMessageStream(
            'ストリームテスト',
            imageBytes: dummyBytes,
          ),
        ).thenAnswer((_) => Stream.fromIterable([expectedEvent]));

        final stream = repository.sendMessageStream(
          'ストリームテスト',
          imageBytes: dummyBytes,
        );

        check(stream).legacyMatcher(emitsInOrder([expectedEvent, emitsDone]));
        verify(
          () => mockApiClient.sendMessageStream(
            'ストリームテスト',
            imageBytes: dummyBytes,
          ),
        ).called(1);
      });
    });

    group('sendFunctionResponseStream (ツール結果返送ストリーム)', () {
      test('正常系: ツール実行結果リストを渡して後続イベントが取得できること', () async {
        const expectedEvent = ChatStreamEvent.text('メモを作成しました。');
        final responses = <ChatFunctionResponse>[
          (name: 'createMemo', response: {'status': 'success'}, id: 'call_1'),
        ];

        when(
          () => mockApiClient.sendFunctionResponseStream(responses),
        ).thenAnswer((_) => Stream.fromIterable([expectedEvent]));

        final stream = repository.sendFunctionResponseStream(responses);

        check(stream).legacyMatcher(emitsInOrder([expectedEvent, emitsDone]));
        verify(
          () => mockApiClient.sendFunctionResponseStream(responses),
        ).called(1);
      });
    });
  });
}
