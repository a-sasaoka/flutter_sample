import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/auth/data/auth_session_lock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('AuthSessionLock', () {
    test('authSessionLockProvider: AuthSessionLockインスタンスを提供すること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final lock = container.read(authSessionLockProvider);

      check(lock).isA<AuthSessionLock>();
    });

    test('synchronized: 並行呼び出しを順番通りに直列実行し、それぞれの戻り値を返すこと', () async {
      final lock = AuthSessionLock();
      final events = <String>[];
      final firstGate = Completer<void>();

      final firstFuture = lock.synchronized(() async {
        events.add('first:start');
        await firstGate.future;
        events.add('first:end');
        return 'result-1';
      });

      final secondFuture = lock.synchronized(() async {
        events
          ..add('second:start')
          ..add('second:end');
        return 'result-2';
      });

      await Future<void>.delayed(Duration.zero);
      // 1つ目の処理が完了するまで、2つ目は開始されないこと
      check(events).deepEquals(['first:start']);

      firstGate.complete();
      final results = await Future.wait([firstFuture, secondFuture]);

      check(results).deepEquals(['result-1', 'result-2']);
      check(
        events,
      ).deepEquals(['first:start', 'first:end', 'second:start', 'second:end']);
    });

    test('synchronized: 先行処理が例外を投げても、後続処理が止まらず順番通りに実行されること', () async {
      final lock = AuthSessionLock();
      final firstGate = Completer<void>();
      final events = <String>[];

      final firstFuture = lock.synchronized<void>(() async {
        events.add('first:start');
        await firstGate.future;
        throw StateError('first failed');
      });

      final secondFuture = lock.synchronized(() async {
        events.add('second:executed');
        return 42;
      });

      await Future<void>.delayed(Duration.zero);
      check(events).deepEquals(['first:start']);

      firstGate.complete();
      await check(firstFuture).throws<StateError>();
      check(await secondFuture).equals(42);
      check(events).deepEquals(['first:start', 'second:executed']);
    });

    test('runSessionTransition: セッション世代が進み、synchronizedでは進まないこと', () async {
      final lock = AuthSessionLock();
      check(lock.sessionEpoch).equals(0);

      await lock.synchronized(() async {});
      check(lock.sessionEpoch).equals(0);

      final result = await lock.runSessionTransition(
        () async => 'transitioned',
      );
      check(result).equals('transitioned');
      check(lock.sessionEpoch).equals(1);
    });

    test('beginDeletion / endDeletion: 削除進行中フラグをネスト安全に管理できること', () {
      final lock = AuthSessionLock();
      check(lock.isDeletionInProgress).equals(false);

      // 未開始状態での endDeletion でも負数にならないこと
      lock.endDeletion();
      check(lock.isDeletionInProgress).equals(false);

      lock.beginDeletion();
      check(lock.isDeletionInProgress).equals(true);

      lock
        ..beginDeletion()
        ..endDeletion();
      check(lock.isDeletionInProgress).equals(true);

      lock.endDeletion();
      check(lock.isDeletionInProgress).equals(false);
    });

    test(
      'runSessionTransitionIf: 条件が true のときのみ世代を進めて action を実行すること',
      () async {
        final lock = AuthSessionLock();
        var actionCalls = 0;

        final skipped = await lock.runSessionTransitionIf(
          shouldTransition: () async => false,
          action: () async {
            actionCalls++;
          },
        );
        check(skipped).equals(false);
        check(actionCalls).equals(0);
        check(lock.sessionEpoch).equals(0);

        final executed = await lock.runSessionTransitionIf(
          shouldTransition: () async => true,
          action: () async {
            actionCalls++;
          },
        );
        check(executed).equals(true);
        check(actionCalls).equals(1);
        check(lock.sessionEpoch).equals(1);
      },
    );
  });
}
