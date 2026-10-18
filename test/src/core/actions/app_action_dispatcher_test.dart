import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/actions/app_action_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:legacy_checks/legacy_checks.dart';

void main() {
  group('appActionDispatcherProvider テスト', () {
    test(
      '未オーバーライド時に読み取ろうとすると ProviderException(UnimplementedError) がスローされること',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        check(() => container.read(appActionDispatcherProvider)).legacyMatcher(
          throwsA(
            predicate((e) => e.toString().contains('UnimplementedError')),
          ),
        );
      },
    );
  });
}
