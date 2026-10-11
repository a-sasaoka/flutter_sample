import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/services/lock_suppression_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('LockSuppressionHandler Tests', () {
    test(
      'lockSuppressionRunnerProvider: デフォルト実装がアクションを透過的に実行し結果を返すこと',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Core層のデフォルト実装を取得
        final runner = container.read(lockSuppressionRunnerProvider);

        var executed = false;
        final result = await runner<String>(() async {
          executed = true;
          return 'test_result';
        });

        check(executed).equals(true);
        check(result).equals('test_result');
      },
    );

    test(
      'lockSuppressionRunnerProvider: isSuccess 述語が渡された場合も透過的にアクションを実行すること',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final runner = container.read(lockSuppressionRunnerProvider);

        var executed = false;
        final result = await runner<int>(() async {
          executed = true;
          return 100;
        }, isSuccess: (res) => res > 0);

        check(executed).equals(true);
        check(result).equals(100);
      },
    );

    test(
      'lockSuppressionRunnerProvider: アクション内で例外が発生した場合は透過的に再送出されること',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final runner = container.read(lockSuppressionRunnerProvider);

        await check(
          runner<void>(() async {
            throw StateError('Runner failure');
          }),
        ).throws<StateError>();
      },
    );
  });
}
