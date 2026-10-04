import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/chat/data/gemini_api_client.dart';
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

    test('HEIC画像の場合、image/heic が返されること', () {
      final heicBytes = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x18,
        0x66, 0x74, 0x79, 0x70, // ftyp
        0x68, 0x65, 0x69, 0x63, // heic
      ]);

      final result = detectImageMimeType(heicBytes);

      check(result).equals('image/heic');
    });

    test('判定不能なバイト列の場合、フォールバックとして image/jpeg が返されること', () {
      final unknownBytes = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);

      final result = detectImageMimeType(unknownBytes);

      check(result).equals('image/jpeg');
    });

    test('空のバイト列の場合、フォールバックとして image/jpeg が返されること', () {
      final emptyBytes = Uint8List(0);

      final result = detectImageMimeType(emptyBytes);

      check(result).equals('image/jpeg');
    });
  });
}
