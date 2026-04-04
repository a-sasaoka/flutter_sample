import 'dart:async';

import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';
import 'package:flutter_sample/src/features/chat/data/chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';
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
        expect(result, 'こんにちは！AIです。');
        verify(() => mockApiClient.sendMessage('テストプロンプト')).called(1);
      });

      test(
        '異常系: AIからの返答が空文字("")の場合、ChatEmptyResponseExceptionを投げること',
        () async {
          when(
            () => mockApiClient.sendMessage(any()),
          ).thenAnswer((_) async => '');

          // 例外が投げられることを検証
          expect(
            () => repository.sendMessage('テスト'),
            throwsA(isA<ChatEmptyResponseException>()),
          );
        },
      );

      test('異常系: AIからの返答がnullの場合、ChatEmptyResponseExceptionを投げること', () async {
        when(
          () => mockApiClient.sendMessage(any()),
        ).thenAnswer((_) async => null);

        // nullの場合も同様に例外になることを検証
        expect(
          () => repository.sendMessage('テスト'),
          throwsA(isA<ChatEmptyResponseException>()),
        );
      });
    });

    group('sendMessageStream (ストリーム)', () {
      test('正常系: Streamの各チャンクが順番に返され、nullは空文字に変換されること', () async {
        // Arrange: モックのStreamが ['AI', null, 'からの返答'] の順で流れてくると仮定
        when(
          () => mockApiClient.sendMessageStream('ストリームテスト'),
        ).thenAnswer((_) => Stream.fromIterable(['AI', null, 'からの返答']));

        // Act: Streamを取得
        final stream = repository.sendMessageStream('ストリームテスト');

        // Assert: Streamから流れてくる値を順番に検証
        // .map((text) => text ?? '') のロジックによって、nullが空文字に変換されることを確認
        expect(
          stream,
          emitsInOrder([
            'AI',
            '', // null が 空文字('') に変換されていること！
            'からの返答',
            emitsDone, // Streamが正しく完了すること
          ]),
        );
      });
    });
  });
}
