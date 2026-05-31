import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartItem', () {
    test('デフォルト値が正しく設定されること', () {
      const item = ChartItem(id: 'test-id');

      check(item.id).equals('test-id');
      check(item.label).equals('');
      check(item.value).equals(0);
    });

    test('指定した値でインスタンスが生成されること', () {
      const item = ChartItem(id: 'test-id', label: 'Item 1', value: 10.5);

      check(item.id).equals('test-id');
      check(item.label).equals('Item 1');
      check(item.value).equals(10.5);
    });

    test('fromJsonで正しくインスタンスが生成されること', () {
      final json = {
        'id': 'test-id',
        'label': 'Item 1',
        'value': 10.5,
      };

      final item = ChartItem.fromJson(json);

      check(item.id).equals('test-id');
      check(item.label).equals('Item 1');
      check(item.value).equals(10.5);
    });

    test('toJsonで正しいMapに変換されること', () {
      const item = ChartItem(id: 'test-id', label: 'Item 1', value: 10.5);
      final json = item.toJson();

      check(json).deepEquals({
        'id': 'test-id',
        'label': 'Item 1',
        'value': 10.5,
      });
    });
  });
}
