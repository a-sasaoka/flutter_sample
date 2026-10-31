import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/memos/application/memo_filter_notifier.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_category.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_sort_order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('MemoFilterNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態が正しく設定されていること', () {
      final state = container.read(memoFilterProvider);
      check(state.query).equals('');
      check(state.category).isNull();
      check(state.unsyncedOnly).equals(false);
      check(state.sortOrder).equals(MemoSortOrder.createdAtDesc);
      check(state.hasActiveFilter).equals(false);
    });

    test('setQuery で検索クエリが更新され、hasActiveFilter が正しく判定されること', () {
      container.read(memoFilterProvider.notifier).setQuery('flutter');
      check(container.read(memoFilterProvider).query).equals('flutter');
      check(container.read(memoFilterProvider).hasActiveFilter).equals(true);

      container.read(memoFilterProvider.notifier).setQuery('');
      check(container.read(memoFilterProvider).query).equals('');
      check(container.read(memoFilterProvider).hasActiveFilter).equals(false);
    });

    test('toggleCategory と setCategory が正しく動作すること', () {
      container
          .read(memoFilterProvider.notifier)
          .toggleCategory(MemoCategory.work);
      check(
        container.read(memoFilterProvider).category,
      ).equals(MemoCategory.work);
      check(container.read(memoFilterProvider).hasActiveFilter).equals(true);

      // 同じカテゴリを再度トグルすると選択解除（null）になること
      container
          .read(memoFilterProvider.notifier)
          .toggleCategory(MemoCategory.work);
      check(container.read(memoFilterProvider).category).isNull();
      check(container.read(memoFilterProvider).hasActiveFilter).equals(false);

      // setCategory で明示的に設定
      container
          .read(memoFilterProvider.notifier)
          .setCategory(MemoCategory.idea);
      check(
        container.read(memoFilterProvider).category,
      ).equals(MemoCategory.idea);
    });

    test('toggleUnsyncedOnly と setUnsyncedOnly が正しく動作すること', () {
      container.read(memoFilterProvider.notifier).toggleUnsyncedOnly();
      check(container.read(memoFilterProvider).unsyncedOnly).equals(true);
      check(container.read(memoFilterProvider).hasActiveFilter).equals(true);

      container.read(memoFilterProvider.notifier).toggleUnsyncedOnly();
      check(container.read(memoFilterProvider).unsyncedOnly).equals(false);
      check(container.read(memoFilterProvider).hasActiveFilter).equals(false);

      // setUnsyncedOnly で明示的に設定
      container
          .read(memoFilterProvider.notifier)
          .setUnsyncedOnly(unsyncedOnly: true);
      check(container.read(memoFilterProvider).unsyncedOnly).equals(true);
    });

    test('setSortOrder が正しく動作すること', () {
      container
          .read(memoFilterProvider.notifier)
          .setSortOrder(MemoSortOrder.titleAsc);
      check(
        container.read(memoFilterProvider).sortOrder,
      ).equals(MemoSortOrder.titleAsc);
    });

    test('resetFilter で全条件が初期値にリセットされること', () {
      container.read(memoFilterProvider.notifier)
        ..setQuery('test')
        ..setCategory(MemoCategory.work)
        ..setUnsyncedOnly(unsyncedOnly: true)
        ..setSortOrder(MemoSortOrder.titleAsc)
        ..resetFilter();
      final resetState = container.read(memoFilterProvider);
      check(resetState.query).equals('');
      check(resetState.category).isNull();
      check(resetState.unsyncedOnly).equals(false);
      check(resetState.sortOrder).equals(MemoSortOrder.titleAsc);
      check(resetState.hasActiveFilter).equals(false);
    });
  });
}
