import 'package:flutter_sample/src/features/chart/application/chart_notifier.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  ProviderContainer makeProviderContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('ChartNotifier', () {
    test('初期状態が正しいこと', () {
      final container = makeProviderContainer();
      final state = container.read(chartProvider);

      expect(state.items.length, 2);
      expect(state.chartType, ChartType.line);
    });

    test('グラフの種類を更新できること', () {
      final container = makeProviderContainer();
      container.read(chartProvider.notifier).updateChartType(ChartType.bar);
      expect(container.read(chartProvider).chartType, ChartType.bar);
    });

    test('項目を追加できること', () {
      final container = makeProviderContainer();
      container.read(chartProvider.notifier).addItem();
      expect(container.read(chartProvider).items.length, 3);
      expect(container.read(chartProvider).items.last.label, 'Item3');
    });

    test('項目を削除した後に再度追加してもラベルが重複しないこと', () {
      final container = makeProviderContainer();
      final id1 = container.read(chartProvider).items.first.id;

      // Item1(id1) を削除 -> 現在は Item2 のみ
      container.read(chartProvider.notifier).removeItem(id1);
      expect(container.read(chartProvider).items.length, 1);

      // 追加 -> Item2 があるので、次は Item3 になるべき（Item2とは重複しない）
      container.read(chartProvider.notifier).addItem();
      expect(container.read(chartProvider).items.length, 2);
      expect(
        container.read(chartProvider).items.any((i) => i.label == 'Item3'),
        isTrue,
      );
    });

    test('項目を削除できること', () {
      final container = makeProviderContainer();
      final firstId = container.read(chartProvider).items.first.id;

      container.read(chartProvider.notifier).removeItem(firstId);
      expect(container.read(chartProvider).items.length, 1);
      expect(
        container.read(chartProvider).items.any((i) => i.id == firstId),
        isFalse,
      );
    });

    test('ラベルを更新できること', () {
      final container = makeProviderContainer();
      final firstId = container.read(chartProvider).items.first.id;

      container.read(chartProvider.notifier).updateLabel(firstId, '更新済み');
      expect(container.read(chartProvider).items.first.label, '更新済み');
    });

    test('数値を更新できること', () {
      final container = makeProviderContainer();
      final firstId = container.read(chartProvider).items.first.id;

      container.read(chartProvider.notifier).updateValue(firstId, 100.5);
      expect(container.read(chartProvider).items.first.value, 100.5);
    });
  });
}
