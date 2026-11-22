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

    test('名前付きファクトリコンストラクタから各具象クラスが生成できること', () {
      const requiresRecentLogin = ReauthException.requiresRecentLogin();
      const wrongPassword = ReauthException.wrongPassword();
      const userMismatch = ReauthException.userMismatch();
      const cancelled = ReauthException.cancelled();
      const tooManyRequests = ReauthException.tooManyRequests();
      const missingEmail = ReauthException.missingEmail();

      check(requiresRecentLogin).isA<ReauthRequiresRecentLoginException>();
      check(wrongPassword).isA<ReauthWrongPasswordException>();
      check(userMismatch).isA<ReauthUserMismatchException>();
      check(cancelled).isA<ReauthCancelledException>();
      check(tooManyRequests).isA<ReauthTooManyRequestsException>();
      check(missingEmail).isA<ReauthMissingEmailException>();

      for (final exception in const <ReauthException>[
        requiresRecentLogin,
        wrongPassword,
        userMismatch,
        cancelled,
        tooManyRequests,
        missingEmail,
      ]) {
        check(exception).isA<ReauthException>();
        check(exception).isA<Exception>();
      }
    });

    test('Freezed による値比較（等価性）が正しく動作すること', () {
      check(
        const ReauthException.wrongPassword(),
      ).equals(const ReauthWrongPasswordException());

      // 値比較 (== / hashCode) を確認するため意図的に非constインスタンスを生成
      // ignore: prefer_const_constructors
      final nonConstWrongPassword = ReauthWrongPasswordException();
      check<ReauthException>(
        nonConstWrongPassword,
      ).equals(const ReauthException.wrongPassword());
      check(
        nonConstWrongPassword.hashCode,
      ).equals(const ReauthException.wrongPassword().hashCode);

      check(
        const ReauthException.wrongPassword(),
      ).not((it) => it.equals(const ReauthException.cancelled()));
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
