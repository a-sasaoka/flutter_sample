import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/app_lock/data/local_authentication_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  group('LocalAuthenticationProvider Tests', () {
    test(
      'localAuthenticationProvider: 正常に LocalAuthentication インスタンスを生成する',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final localAuth = container.read(localAuthenticationProvider);
        check(localAuth).isA<LocalAuthentication>();
      },
    );
  });
}
