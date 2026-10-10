import 'dart:convert';

/// 🔐 JWT (JSON Web Token) のデコード・ユーティリティ
abstract final class JwtUtils {
  /// JWT トークンからペイロードの JSON を抽出してデコードします。
  ///
  /// トークンが無効または不正な形式（パート数が3以外、Base64Urlデコード不可、JSONではない等）の場合は null を返します。
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decodedBytes = base64Url.decode(normalized);
      final decodedString = utf8.decode(decodedBytes);
      final dynamic json = jsonDecode(decodedString);
      if (json is Map<String, dynamic>) {
        return json;
      }
      return null;
    } on Object {
      return null;
    }
  }

  /// JWT トークンからユーザーID（`sub` クレーム）を取得します。
  ///
  /// ペイロード内に `sub` が存在しない、または文字列型でない場合は null を返します。
  static String? getUserId(String token) {
    final payload = decodePayload(token);
    final sub = payload?['sub'];
    return sub is String ? sub : null;
  }
}
