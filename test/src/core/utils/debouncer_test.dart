import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/utils/debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debouncer テスト', () {
    testWidgets('【正常系】指定時間（400ms）経過後にコールバックが実行されること', (tester) async {
      final debouncer = Debouncer();
      var callCount = 0;

      debouncer.run(() {
        callCount++;
      });

      // 呼び出し直後
      check(debouncer.isActive).isTrue();
      check(callCount).equals(0);

      // 399ms時点ではまだ実行されない
      await tester.pump(const Duration(milliseconds: 399));
      check(callCount).equals(0);
      check(debouncer.isActive).isTrue();

      // 400ms経過で実行完了
      await tester.pump(const Duration(milliseconds: 1));
      check(callCount).equals(1);
      check(debouncer.isActive).isFalse();
    });

    testWidgets('【正常系】待機中に再度runが呼ばれた場合、前の処理はキャンセルされタイマーが延長されること', (
      tester,
    ) async {
      final debouncer = Debouncer();
      final executionLog = <String>[];

      debouncer.run(() {
        executionLog.add('first');
      });

      // 200ms後に2回目の呼び出し
      await tester.pump(const Duration(milliseconds: 200));
      debouncer.run(() {
        executionLog.add('second');
      });

      // 最初の呼び出しから400ms後（2回目から200ms後）はまだ未実行
      await tester.pump(const Duration(milliseconds: 200));
      check(executionLog).isEmpty();

      // 2回目の呼び出しから400ms経過で実行
      await tester.pump(const Duration(milliseconds: 200));
      check(executionLog).deepEquals(['second']);
    });

    testWidgets('【正常系】cancel() を呼び出すと待機中のコールバックが実行されないこと', (tester) async {
      final debouncer = Debouncer();
      var callCount = 0;

      debouncer.run(() {
        callCount++;
      });

      await tester.pump(const Duration(milliseconds: 200));
      debouncer.cancel();

      check(debouncer.isActive).isFalse();

      // 時間が経過しても実行されない
      await tester.pump(const Duration(milliseconds: 500));
      check(callCount).equals(0);
    });

    testWidgets('【正常系】dispose() を呼び出すと待機中の処理が安全に破棄されること', (tester) async {
      var callCount = 0;
      final debouncer = Debouncer()
        ..run(() {
          callCount++;
        })
        ..dispose();

      check(debouncer.isActive).isFalse();

      await tester.pump(const Duration(milliseconds: 500));
      check(callCount).equals(0);
    });

    testWidgets('【正常系】カスタムの遅延時間を設定した場合、その時間で正しく動作すること', (tester) async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 200));
      var callCount = 0;

      debouncer.run(() {
        callCount++;
      });

      await tester.pump(const Duration(milliseconds: 199));
      check(callCount).equals(0);

      await tester.pump(const Duration(milliseconds: 1));
      check(callCount).equals(1);
    });
  });
}
