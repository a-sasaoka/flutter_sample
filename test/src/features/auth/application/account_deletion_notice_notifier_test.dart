import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/auth/application/account_deletion_notice_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('AccountDeletionNoticeNotifier', () {
    test('初期状態は none であること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      check(
        container.read(accountDeletionNoticeProvider),
      ).equals(AccountDeletionNoticeStatus.none);
    });

    test('reserve なしで confirmCompleted を呼んでも completed に遷移しないこと', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(accountDeletionNoticeProvider.notifier)
        ..confirmCompleted();

      check(
        container.read(accountDeletionNoticeProvider),
      ).equals(AccountDeletionNoticeStatus.none);
      check(notifier.consume()).isFalse();
    });

    test('reserve 中は reserved となり、consume が false を返して予約状態を維持すること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(accountDeletionNoticeProvider.notifier)
        ..reserve();
      check(
        container.read(accountDeletionNoticeProvider),
      ).equals(AccountDeletionNoticeStatus.reserved);

      check(notifier.consume()).isFalse();
      check(
        container.read(accountDeletionNoticeProvider),
      ).equals(AccountDeletionNoticeStatus.reserved);
    });

    test('reserve 後に confirmCompleted で completed になり、 '
        'consume は1回目のみ true を返して none に戻すこと', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(accountDeletionNoticeProvider.notifier)
        ..reserve()
        ..confirmCompleted();
      check(
        container.read(accountDeletionNoticeProvider),
      ).equals(AccountDeletionNoticeStatus.completed);

      final firstConsume = notifier.consume();
      check(firstConsume).isTrue();
      check(
        container.read(accountDeletionNoticeProvider),
      ).equals(AccountDeletionNoticeStatus.none);

      final secondConsume = notifier.consume();
      check(secondConsume).isFalse();
      check(
        container.read(accountDeletionNoticeProvider),
      ).equals(AccountDeletionNoticeStatus.none);
    });

    test('clear を呼ぶと reserved / completed が none に戻り、 '
        '再予約なしでは確定できないこと', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(accountDeletionNoticeProvider.notifier)
        ..reserve()
        ..clear()
        ..confirmCompleted();

      check(
        container.read(accountDeletionNoticeProvider),
      ).equals(AccountDeletionNoticeStatus.none);

      notifier
        ..reserve()
        ..confirmCompleted()
        ..clear();

      check(
        container.read(accountDeletionNoticeProvider),
      ).equals(AccountDeletionNoticeStatus.none);
    });
  });
}
