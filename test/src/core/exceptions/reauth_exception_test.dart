import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/exceptions/reauth_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReauthException テスト', () {
    test('各サブクラスが ReauthException および Exception として生成できること', () {
      const exceptions = <ReauthException>[
        ReauthRequiresRecentLoginException(),
        ReauthWrongPasswordException(),
        ReauthUserMismatchException(),
        ReauthCancelledException(),
        ReauthTooManyRequestsException(),
        ReauthMissingEmailException(),
      ];

      for (final exception in exceptions) {
        check(exception).isA<ReauthException>();
        check(exception).isA<Exception>();
      }
    });

    test('switch式で全6種類を網羅的にパターンマッチできること', () {
      String describe(ReauthException exception) {
        return switch (exception) {
          ReauthRequiresRecentLoginException() => 'requires_recent_login',
          ReauthWrongPasswordException() => 'wrong_password',
          ReauthUserMismatchException() => 'user_mismatch',
          ReauthCancelledException() => 'cancelled',
          ReauthTooManyRequestsException() => 'too_many_requests',
          ReauthMissingEmailException() => 'missing_email',
        };
      }

      check(
        describe(const ReauthRequiresRecentLoginException()),
      ).equals('requires_recent_login');
      check(
        describe(const ReauthWrongPasswordException()),
      ).equals('wrong_password');
      check(
        describe(const ReauthUserMismatchException()),
      ).equals('user_mismatch');
      check(describe(const ReauthCancelledException())).equals('cancelled');
      check(
        describe(const ReauthTooManyRequestsException()),
      ).equals('too_many_requests');
      check(
        describe(const ReauthMissingEmailException()),
      ).equals('missing_email');
    });
  });
}
