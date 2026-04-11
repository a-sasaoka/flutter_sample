import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Flavor enum テスト', () {
    test('fromString() が正しい文字列から Flavor を返すこと（大文字小文字区別なし）', () {
      // Assert: 完全一致
      expect(Flavor.fromString('local'), equals(Flavor.local));
      expect(Flavor.fromString('dev'), equals(Flavor.dev));
      expect(Flavor.fromString('stg'), equals(Flavor.stg));
      expect(Flavor.fromString('prod'), equals(Flavor.prod));

      // Assert: 大文字が混ざっていても .toLowerCase() により正常に変換されること
      expect(Flavor.fromString('DEV'), equals(Flavor.dev));
      expect(Flavor.fromString('Stg'), equals(Flavor.stg));
    });

    test('fromString() が無効な文字列を渡された時に ArgumentError を投げること', () {
      // Assert: 想定外の文字列が来たら、意図通りにクラッシュすることを確認
      expect(
        () => Flavor.fromString('qa'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => Flavor.fromString(''), // 空文字
        throwsA(isA<ArgumentError>()),
      );
    });
  });

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
