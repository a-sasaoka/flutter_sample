import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppException テスト', () {
    group('NetworkException', () {
      test('通常のネットワークエラーの場合、正しいmessageKeyを返すこと', () {
        const exception = NetworkException(statusCode: 404);

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
      test('正しいmessageKeyを返すこと', () {
        const exception = TimeoutException();

        expect(exception.messageKey, equals('errorTimeout'));
      });
    });

    group('UnknownException', () {
      test('正しいmessageKey、および任意のメッセージを保持できること', () {
        const exception = UnknownException(message: 'some error');

        expect(exception.messageKey, equals('errorUnknown'));
        expect(exception.message, equals('some error'));
      });
    });

    test('toString() が正しい文字列表現を返すこと', () {
      expect(
        const NetworkException().toString(),
        equals('NetworkException(statusCode: null, code: null)'),
      );
      expect(
        const TimeoutException().toString(),
        equals('TimeoutException(code: null)'),
      );
      expect(
        const UnknownException().toString(),
        equals('UnknownException(message: null, code: null)'),
      );
    });
  });
}
