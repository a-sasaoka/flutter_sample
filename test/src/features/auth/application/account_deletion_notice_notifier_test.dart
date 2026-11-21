import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/auth/application/account_deletion_notice_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('AccountDeletionNoticeNotifier', () {
    test('初期状態は false であること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      check(container.read(accountDeletionNoticeProvider)).isFalse();
    });

    test('markCompleted で true になり、consume は1回目のみ true を返して false に戻すこと', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(accountDeletionNoticeProvider.notifier)
        ..markCompleted();
      check(container.read(accountDeletionNoticeProvider)).isTrue();

      final firstConsume = notifier.consume();
      check(firstConsume).isTrue();
      check(container.read(accountDeletionNoticeProvider)).isFalse();

      final secondConsume = notifier.consume();
      check(secondConsume).isFalse();
      check(container.read(accountDeletionNoticeProvider)).isFalse();
    });

    test('clear を呼ぶと true の状態が false にリセットされること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(accountDeletionNoticeProvider.notifier)
        ..markCompleted()
        ..clear();

      check(container.read(accountDeletionNoticeProvider)).isFalse();
    });
  });
}
