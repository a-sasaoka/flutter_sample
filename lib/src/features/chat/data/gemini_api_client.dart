// coverage:ignore-file
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sample/src/features/chat/data/chat_api_client.dart';

/// 画像データの先頭バイト（マジックナンバー）からMIMEタイプを判定する
/// 判定不能な場合はフォールバックとして 'image/jpeg' を返す
@visibleForTesting
String detectImageMimeType(Uint8List bytes) {
  // PNG: 89 50 4E 47 0D 0A 1A 0A
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return 'image/png';
  }
  // JPEG: FF D8 FF
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  // WebP: RIFF .... WEBP
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  // HEIC / HEIF: ftypheic, ftypmif1 など
  if (bytes.length >= 12 &&
      bytes[4] == 0x66 &&
      bytes[5] == 0x74 &&
      bytes[6] == 0x79 &&
      bytes[7] == 0x70) {
    final brand = String.fromCharCodes(bytes.sublist(8, 12));
    if (brand == 'heic' ||
        brand == 'heix' ||
        brand == 'mif1' ||
        brand == 'msf1') {
      return 'image/heic';
    }
  }
  return 'image/jpeg';
}

/// Gemini APIクライアントの実装
class GeminiApiClient implements ChatApiClient {
  /// コンストラクタ
  GeminiApiClient(this._session);
  final ChatSession _session;

  Content _buildContent(String prompt, Uint8List? imageBytes) {
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final mimeType = detectImageMimeType(imageBytes);
      return Content.multi([
        TextPart(prompt),
        InlineDataPart(mimeType, imageBytes),
      ]);
    }
    return Content.text(prompt);
  }

  @override
  Future<String?> sendMessage(String prompt, {Uint8List? imageBytes}) async {
    final response = await _session.sendMessage(
      _buildContent(prompt, imageBytes),
    );
    return response.text;
  }

  @override
  Stream<String?> sendMessageStream(String prompt, {Uint8List? imageBytes}) {
    return _session
        .sendMessageStream(_buildContent(prompt, imageBytes))
        .map((chunk) => chunk.text);
  }
}
