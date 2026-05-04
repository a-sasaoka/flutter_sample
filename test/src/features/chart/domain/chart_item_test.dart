import 'package:flutter_sample/src/features/chart/domain/chart_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartItem', () {
    test('デフォルト値が正しく設定されること', () {
      const item = ChartItem(id: 'test-id');

      expect(item.id, 'test-id');
      expect(item.label, '');
      expect(item.value, 0.0);
    });

    test('指定した値でインスタンスが生成されること', () {
      const item = ChartItem(id: 'test-id', label: 'Item 1', value: 10.5);

      expect(item.id, 'test-id');
      expect(item.label, 'Item 1');
      expect(item.value, 10.5);
    });

    test('fromJsonで正しくインスタンスが生成されること', () {
      final json = {
        'id': 'test-id',
        'label': 'Item 1',
        'value': 10.5,
      };

      final item = ChartItem.fromJson(json);

      expect(item.id, 'test-id');
      expect(item.label, 'Item 1');
      expect(item.value, 10.5);
    });

    test('toJsonで正しいMapに変換されること', () {
      const item = ChartItem(id: 'test-id', label: 'Item 1', value: 10.5);
      final json = item.toJson();

      expect(json, {
        'id': 'test-id',
        'label': 'Item 1',
        'value': 10.5,
      });
    });
  });
}
