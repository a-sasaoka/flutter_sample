import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppException テスト', () {
    test('NetworkException が正しく生成されること', () {
      const exception = AppException.network(message: 'offline');
      expect(exception, isA<NetworkException>());
      expect(exception.message, 'offline');
    });

    test('ServerException が正しく生成されること', () {
      const exception = AppException.server(statusCode: 500, message: 'error');
      expect(exception, isA<ServerException>());
      expect(exception.statusCode, 500);
      expect(exception.message, 'error');
    });

    test('BadRequestException が正しく生成されること', () {
      const exception = AppException.badRequest(
        statusCode: 400,
        message: 'invalid',
      );
      expect(exception, isA<BadRequestException>());
      expect(exception.statusCode, 400);
      expect(exception.message, 'invalid');
    });

    test('UnauthenticatedException が正しく生成されること', () {
      const exception = AppException.unauthenticated(message: 'not logged in');
      expect(exception, isA<UnauthenticatedException>());
      expect(exception.message, 'not logged in');
    });

    test('UnauthorizedException が正しく生成されること', () {
      const exception = AppException.unauthorized(message: 'forbidden');
      expect(exception, isA<UnauthorizedException>());
      expect(exception.message, 'forbidden');
    });

    test('TimeoutException が正しく生成されること', () {
      const exception = AppException.timeout(message: 'timeout');
      expect(exception, isA<TimeoutException>());
      expect(exception.message, 'timeout');
    });

    test('DataParseException が正しく生成されること', () {
      const exception = AppException.dataParse(message: 'parse error');
      expect(exception, isA<DataParseException>());
      expect(exception.message, 'parse error');
    });

    test('DatabaseException が正しく生成されること', () {
      final innerError = StateError('db error');
      final exception = AppException.database(
        message: 'storage error',
        error: innerError,
      );
      expect(exception, isA<DatabaseException>());
      expect(exception.message, 'storage error');
      expect(exception.error, innerError);
    });

    test('CancelException が正しく生成されること', () {
      const exception = AppException.cancel(message: 'canceled');
      expect(exception, isA<CancelException>());
      expect(exception.message, 'canceled');
    });

    test('UnknownException が正しく生成されること', () {
      final innerError = StateError('bad state');
      final exception = AppException.unknown(
        message: 'unknown',
        error: innerError,
      );
      expect(exception, isA<UnknownException>());
      expect(exception.message, 'unknown');
      expect(exception.error, innerError);
    });

    test('pattern matching (switch expression) が正しく動作すること', () {
      const exception = AppException.timeout();
      final result = switch (exception) {
        NetworkException() => 'network',
        ServerException() => 'server',
        BadRequestException() => 'badRequest',
        UnauthenticatedException() => 'unauthenticated',
        UnauthorizedException() => 'unauthorized',
        TimeoutException() => 'timeout',
        DataParseException() => 'dataParse',
        DatabaseException() => 'database',
        CancelException() => 'cancel',
        UnknownException() => 'unknown',
      };
      expect(result, 'timeout');
    });
  });
}
