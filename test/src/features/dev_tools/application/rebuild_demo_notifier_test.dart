import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/dev_tools/application/rebuild_demo_notifier.dart';
import 'package:flutter_sample/src/features/dev_tools/domain/rebuild_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('RebuildDemoNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態が正しくセットアップされていること', () {
      // AutoDispose対策
      container.listen(rebuildDemoProvider, (_, _) {});

      final state = container.read(rebuildDemoProvider);

      check(state.isOptimized).isFalse();
      check(state.searchQuery).equals('');
      check(state.items).length.equals(defaultRebuildItems.length);
      check(state.filteredItems).length.equals(defaultRebuildItems.length);
    });

    test('toggleOptimization() で最適化モードが反転すること', () {
      container.listen(rebuildDemoProvider, (_, _) {});

      // 1回目: false -> true
      container.read(rebuildDemoProvider.notifier).toggleOptimization();
      check(container.read(rebuildDemoProvider).isOptimized).isTrue();

      // 2回目: true -> false
      container.read(rebuildDemoProvider.notifier).toggleOptimization();
      check(container.read(rebuildDemoProvider).isOptimized).isFalse();
    });

    test('updateSearchQuery() でクエリが更新され、filteredItems が正しく絞り込まれること', () {
      container.listen(rebuildDemoProvider, (_, _) {});

      // 'container' で検索（大文字小文字を問わず Container, AnimatedContainer がヒット）
      container
          .read(rebuildDemoProvider.notifier)
          .updateSearchQuery('container');
      final state = container.read(rebuildDemoProvider);

      check(state.searchQuery).equals('container');
      check(state.filteredItems).length.equals(2);

      // カテゴリ名 'レイアウト' で検索
      container.read(rebuildDemoProvider.notifier).updateSearchQuery('レイアウト');
      final layoutState = container.read(rebuildDemoProvider);
      check(layoutState.filteredItems).length.equals(2); // Container, Stack

      // 該当なしのキーワード
      container
          .read(rebuildDemoProvider.notifier)
          .updateSearchQuery('xyz_not_found');
      final emptyState = container.read(rebuildDemoProvider);
      check(emptyState.filteredItems).isEmpty();

      // 空文字・空白のみの場合は全件表示
      container.read(rebuildDemoProvider.notifier).updateSearchQuery('   ');
      final allState = container.read(rebuildDemoProvider);
      check(allState.filteredItems).length.equals(defaultRebuildItems.length);
    });

    test('reset() で初期状態にリセットされること', () {
      container.listen(rebuildDemoProvider, (_, _) {});

      // 状態を変更
      container.read(rebuildDemoProvider.notifier)
        ..toggleOptimization()
        ..updateSearchQuery('Button');

      check(container.read(rebuildDemoProvider).isOptimized).isTrue();
      check(container.read(rebuildDemoProvider).searchQuery).equals('Button');

      // リセット
      container.read(rebuildDemoProvider.notifier).reset();

      final resetState = container.read(rebuildDemoProvider);
      check(resetState.isOptimized).isFalse();
      check(resetState.searchQuery).equals('');
      check(resetState.filteredItems).length.equals(defaultRebuildItems.length);
    });
  });
}
