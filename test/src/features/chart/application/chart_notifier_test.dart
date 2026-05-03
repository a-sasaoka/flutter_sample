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

    test('項目を削除できること', () {
      final container = makeProviderContainer();
      container.read(chartProvider.notifier).removeItem(0);
      expect(container.read(chartProvider).items.length, 1);
      expect(container.read(chartProvider).items.first.label, 'Item2');
    });

    test('ラベルを更新できること', () {
      final container = makeProviderContainer();
      container.read(chartProvider.notifier).updateLabel(0, '更新済み');
      expect(container.read(chartProvider).items.first.label, '更新済み');
    });

    test('数値を更新できること', () {
      final container = makeProviderContainer();
      container.read(chartProvider.notifier).updateValue(0, 100.5);
      expect(container.read(chartProvider).items.first.value, 100.5);
    });
  });
}
