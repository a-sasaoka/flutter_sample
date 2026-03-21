import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppException テスト', () {
    group('NetworkException', () {
      test('通常のネットワークエラーの場合、正しいtypeとmessageKeyを返すこと', () {
        const exception = NetworkException(statusCode: 404);

        expect(exception.type, equals(ExceptionType.network));
        expect(exception.messageKey, equals('errorNetwork'));
        expect(exception.statusCode, equals(404));
      });

      test('statusCodeが500以上の場合、messageKeyが errorServer になること', () {
        const exception = NetworkException(statusCode: 500);

        expect(exception.messageKey, equals('errorServer'));
      });

      test('statusCodeがnullの場合、デフォルトの errorNetwork を返すこと', () {
        const exception = NetworkException();

        expect(exception.messageKey, equals('errorNetwork'));
      });
    });

    group('TimeoutException', () {
      test('正しいtypeとmessageKeyを返すこと', () {
        const exception = TimeoutException();

        expect(exception.type, equals(ExceptionType.timeout));
        expect(exception.messageKey, equals('errorTimeout'));
      });
    });

    group('UnknownException', () {
      test('正しいtypeとmessageKey、および任意のメッセージを保持できること', () {
        const exception = UnknownException(message: 'some error');

        expect(exception.type, equals(ExceptionType.unknown));
        expect(exception.messageKey, equals('errorUnknown'));
        expect(exception.message, equals('some error'));
      });
    });

    test('toString() が type.name を返すこと', () {
      expect(const NetworkException().toString(), equals('network'));
      expect(const TimeoutException().toString(), equals('timeout'));
      expect(const UnknownException().toString(), equals('unknown'));
    });
  });
}
