import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/utils/jwt_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JwtUtils', () {
    String createTestJwt(Map<String, dynamic> payload) {
      final header = base64Url
          .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})))
          .replaceAll('=', '');
      final body = base64Url
          .encode(utf8.encode(jsonEncode(payload)))
          .replaceAll('=', '');
      return '$header.$body.dummy_signature';
    }

    group('decodePayload', () {
      test('有効なJWTからペイロードMapを正常にデコードできること', () {
        final token = createTestJwt({'sub': 'user_123', 'name': 'テストユーザー'});
        final result = JwtUtils.decodePayload(token);

        check(result).isNotNull();
        check(result!['sub']).equals('user_123');
        check(result['name']).equals('テストユーザー');
      });

      test('ドットの数が異なる不正な形式の場合は null を返すこと', () {
        check(JwtUtils.decodePayload('')).isNull();
        check(JwtUtils.decodePayload('header.payload')).isNull();
        check(
          JwtUtils.decodePayload('header.payload.signature.extra'),
        ).isNull();
      });

      test('ペイロードがBase64Urlでデコードできない不正な文字列の場合は null を返すこと', () {
        check(
          JwtUtils.decodePayload('header.???invalid???.signature'),
        ).isNull();
      });

      test('ペイロードがJSON形式ではない場合は null を返すこと', () {
        final nonJsonBody = base64Url
            .encode(utf8.encode('just a plain string'))
            .replaceAll('=', '');
        check(JwtUtils.decodePayload('header.$nonJsonBody.signature')).isNull();
      });
    });

    group('getUserId', () {
      test('sub クレームが存在する場合にユーザーIDを返すこと', () {
        final token = createTestJwt({'sub': 'usr_abcdef12345'});
        final userId = JwtUtils.getUserId(token);

        check(userId).equals('usr_abcdef12345');
      });

      test('sub クレームが存在しない場合は null を返すこと', () {
        final token = createTestJwt({'name': '名前のみ'});
        final userId = JwtUtils.getUserId(token);

        check(userId).isNull();
      });

      test('sub クレームが文字列型ではない（数値等）の場合は null を返すこと', () {
        final token = createTestJwt({'sub': 12345});
        final userId = JwtUtils.getUserId(token);

        check(userId).isNull();
      });

      test('不正なトークンの場合は null を返すこと', () {
        check(JwtUtils.getUserId('invalid_token')).isNull();
      });
    });
  });
}
