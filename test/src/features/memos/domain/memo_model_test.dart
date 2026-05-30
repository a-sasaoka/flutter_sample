import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoModel', () {
    test('正常にインスタンス化できること', () {
      final now = DateTime(2026, 5);
      final memo = MemoModel(
        id: '1',
        title: 'テスト',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );

      check(memo.id).equals('1');
      check(memo.title).equals('テスト');
      check(memo.content).equals('内容');
      check(memo.createdAt).equals(now);
    });

    test('同じ値を持つインスタンスは等価と判定されること (Equatable)', () {
      final now = DateTime(2026, 5);
      final memo1 = MemoModel(
        id: '1',
        title: 'テスト',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );
      final memo2 = MemoModel(
        id: '1',
        title: 'テスト',
        content: '内容',
        createdAt: now,
        updatedAt: now,
      );

      check(memo1).equals(memo2);
      check(memo1.hashCode).equals(memo2.hashCode);
    });
  });
}
