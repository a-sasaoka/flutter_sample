import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';
import 'package:flutter_sample/src/features/chat/data/gemini_api_client.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_stream_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectImageMimeType', () {
    test('PNG画像の場合、image/png が返されること', () {
      final pngBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
      ]);

      final result = detectImageMimeType(pngBytes);

      check(result).equals('image/png');
    });

    test('JPEG画像の場合、image/jpeg が返されること', () {
      final jpegBytes = Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0x00,
        0x10,
      ]);

      final result = detectImageMimeType(jpegBytes);

      check(result).equals('image/jpeg');
    });

    test('WebP画像の場合、image/webp が返されること', () {
      final webpBytes = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // RIFF
        0x00, 0x00, 0x00, 0x00,
        0x57, 0x45, 0x42, 0x50, // WEBP
      ]);

      final result = detectImageMimeType(webpBytes);

      check(result).equals('image/webp');
    });

    test('HEIC/HEIF画像（heic, mif1）の場合、未対応形式として null が返されること', () {
      final heicBytes = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x18,
        0x66, 0x74, 0x79, 0x70, // ftyp
        0x68, 0x65, 0x69, 0x63, // heic
      ]);
      final mif1Bytes = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x18,
        0x66, 0x74, 0x79, 0x70, // ftyp
        0x6D, 0x69, 0x66, 0x31, // mif1
      ]);

      check(detectImageMimeType(heicBytes)).isNull();
      check(detectImageMimeType(mif1Bytes)).isNull();
    });

    test('GIF画像の場合、未対応形式として null が返され、image/jpeg と判定されないこと', () {
      final gifBytes = Uint8List.fromList([
        0x47, 0x49, 0x46, 0x38, 0x39, 0x61, // GIF89a
        0x01, 0x00, 0x01, 0x00,
      ]);

      final result = detectImageMimeType(gifBytes);

      check(result).isNull();
    });

    test('判定不能なバイト列の場合、null が返されること', () {
      final unknownBytes = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);

      final result = detectImageMimeType(unknownBytes);

      check(result).isNull();
    });

    test('空のバイト列の場合、null が返されること', () {
      final emptyBytes = Uint8List(0);

      final result = detectImageMimeType(emptyBytes);

      check(result).isNull();
    });
  });

  group('GeminiApiClient.buildContent', () {
    test('画像なしの場合、テキストのみのContentが生成されること', () {
      final content = GeminiApiClient.buildContent('テスト', null);

      check(content.parts.length).equals(1);
      final part = content.parts.first;
      check(part).isA<TextPart>();
    });

    test('対応画像（PNG）の場合、適切なMIMEタイプを持つContentが生成されること', () {
      final pngBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);
      final expectedBytes = Uint8List.fromList(pngBytes);

      final content = GeminiApiClient.buildContent('画像付きテスト', pngBytes);

      check(content.parts.length).equals(2);
      check(content.parts[0]).isA<TextPart>();
      check(content.parts[1]).isA<InlineDataPart>();
      final inlinePart = content.parts[1] as InlineDataPart;
      check(inlinePart.mimeType).equals('image/png');
      check(inlinePart.bytes).deepEquals(expectedBytes);
    });

    test('未対応画像（GIF）の場合、ChatUnsupportedImageFormatException がスローされること', () {
      final gifBytes = Uint8List.fromList([
        0x47, 0x49, 0x46, 0x38, 0x39, 0x61, // GIF89a
      ]);

      check(
        () => GeminiApiClient.buildContent('GIFテスト', gifBytes),
      ).throws<ChatUnsupportedImageFormatException>();
    });

    test('未対応画像（HEIC）の場合、ChatUnsupportedImageFormatException がスローされること', () {
      final heicBytes = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x18,
        0x66, 0x74, 0x79, 0x70, // ftyp
        0x68, 0x65, 0x69, 0x63, // heic
      ]);

      check(
        () => GeminiApiClient.buildContent('HEICテスト', heicBytes),
      ).throws<ChatUnsupportedImageFormatException>();
    });

    test('未知のバイト列の場合、ChatUnsupportedImageFormatException がスローされること', () {
      final unknownBytes = Uint8List.fromList([0x00, 0x01, 0x02]);

      check(
        () => GeminiApiClient.buildContent('未知フォーマットテスト', unknownBytes),
      ).throws<ChatUnsupportedImageFormatException>();
    });
  });

  group('chatFunctionDeclarations', () {
    test(
      '4つのツール（createMemo, listMemos, changeThemeMode, searchWeb）が定義されていること',
      () {
        // ツールの合計数が4つになっているか検証
        check(chatFunctionDeclarations.length).equals(4);

        // 各ツールの名前を一覧で取得
        final names = chatFunctionDeclarations.map((d) => d.name).toList();

        // 4つのツール名が正しい順番・内容で定義されているか検証
        check(names).deepEquals([
          'createMemo',
          'listMemos',
          'changeThemeMode',
          'searchWeb',
        ]);
      },
    );
  });

  group('buildFunctionResponsesContent', () {
    test('単一のツール実行結果からContentが生成されること', () {
      final responses = <ChatFunctionResponse>[
        (
          name: 'createMemo',
          response: {'status': 'success', 'title': '買い物'},
          id: 'call_1',
        ),
      ];

      final content = GeminiApiClient.buildFunctionResponsesContent(responses);

      check(content.role).equals('function');
      check(content.parts.length).equals(1);
      check(content.parts[0]).isA<FunctionResponse>();
      final part = content.parts[0] as FunctionResponse;
      check(part.name).equals('createMemo');
      check(part.response).deepEquals({'status': 'success', 'title': '買い物'});
      check(part.id).equals('call_1');
    });

    test('複数のツール実行結果（並列呼び出し）からContentがまとめて生成されること', () {
      final responses = <ChatFunctionResponse>[
        (name: 'createMemo', response: {'status': 'success'}, id: 'call_1'),
        (
          name: 'changeThemeMode',
          response: {'status': 'success', 'theme': 'dark'},
          id: 'call_2',
        ),
      ];

      final content = GeminiApiClient.buildFunctionResponsesContent(responses);

      check(content.role).equals('function');
      check(content.parts.length).equals(2);
      check(content.parts[0]).isA<FunctionResponse>();
      check(content.parts[1]).isA<FunctionResponse>();
      final part1 = content.parts[0] as FunctionResponse;
      final part2 = content.parts[1] as FunctionResponse;
      check(part1.name).equals('createMemo');
      check(part1.id).equals('call_1');
      check(part2.name).equals('changeThemeMode');
      check(part2.id).equals('call_2');
    });
  });
}
