import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/services/app_lock_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('isAppUnlockedProvider', () {
    test('デフォルトではtrue（ロックなし）を返すこと', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isUnlocked = container.read(isAppUnlockedProvider);

      check(isUnlocked).equals(true);
    });
  });
}
