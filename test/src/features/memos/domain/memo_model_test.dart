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

      expect(memo.id, '1');
      expect(memo.title, 'テスト');
      expect(memo.content, '内容');
      expect(memo.createdAt, now);
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

      expect(memo1, memo2);
      expect(memo1.hashCode, memo2.hashCode);
    });
  });
}
