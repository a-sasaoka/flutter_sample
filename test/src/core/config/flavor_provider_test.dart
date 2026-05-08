import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('flavorProvider テスト', () {
    test('デフォルトのまま読み取ろうとすると UnimplementedError が投げられること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Assert: 上書きせずに read すると、Provider内部で UnimplementedError が発生し、
      // Riverpodの仕組みにより ProviderException としてラップされて投げられることを確認
      expect(
        () => container.read(flavorProvider),
        throwsA(
          predicate((e) => e.toString().contains('UnimplementedError')),
        ),
      );
    });

    test('overrideWithValue で上書きすると、その Flavor を返すこと', () {
      // Arrange: stg 環境としてコンテナを作成
      final container = ProviderContainer(
        overrides: [
          flavorProvider.overrideWithValue(Flavor.stg),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final flavor = container.read(flavorProvider);

      // Assert: 上書きした値が正しく取得できること
      expect(flavor, equals(Flavor.stg));
    });
  });
}
