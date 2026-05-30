import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppException テスト', () {
    test('NetworkException が正しく生成されること', () {
      const exception = AppException.network(message: 'offline');
      check(exception).isA<NetworkException>();
      check(exception.message).equals('offline');
    });

    test('ServerException が正しく生成されること', () {
      const exception = AppException.server(statusCode: 500, message: 'error');
      check(exception).isA<ServerException>();
      check(exception.statusCode).equals(500);
      check(exception.message).equals('error');
    });

    test('BadRequestException が正しく生成されること', () {
      const exception = AppException.badRequest(
        statusCode: 400,
        message: 'invalid',
      );
      check(exception).isA<BadRequestException>();
      check(exception.statusCode).equals(400);
      check(exception.message).equals('invalid');
    });

    test('UnauthenticatedException が正しく生成されること', () {
      const exception = AppException.unauthenticated(message: 'not logged in');
      check(exception).isA<UnauthenticatedException>();
      check(exception.message).equals('not logged in');
    });

    test('UnauthorizedException が正しく生成されること', () {
      const exception = AppException.unauthorized(message: 'forbidden');
      check(exception).isA<UnauthorizedException>();
      check(exception.message).equals('forbidden');
    });

    test('TimeoutException が正しく生成されること', () {
      const exception = AppException.timeout(message: 'timeout');
      check(exception).isA<TimeoutException>();
      check(exception.message).equals('timeout');
    });

    test('DataParseException が正しく生成されること', () {
      const exception = AppException.dataParse(message: 'parse error');
      check(exception).isA<DataParseException>();
      check(exception.message).equals('parse error');
    });

    test('DatabaseException が正しく生成されること', () {
      final innerError = StateError('db error');
      final exception = AppException.database(
        message: 'storage error',
        error: innerError,
      );
      check(exception).isA<DatabaseException>();
      check(exception.message).equals('storage error');
      check(exception.error).equals(innerError);
    });

    test('CancelException が正しく生成されること', () {
      const exception = AppException.cancel(message: 'canceled');
      check(exception).isA<CancelException>();
      check(exception.message).equals('canceled');
    });

    test('UnknownException が正しく生成されること', () {
      final innerError = StateError('bad state');
      final exception = AppException.unknown(
        message: 'unknown',
        error: innerError,
      );
      check(exception).isA<UnknownException>();
      check(exception.message).equals('unknown');
      check(exception.error).equals(innerError);
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
      check(result).equals('timeout');
    });
  });
}
