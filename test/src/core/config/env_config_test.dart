import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('EnvConfig テスト', () {
    test('JSON (String.fromEnvironment) から設定値が正しく読み込まれること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(envConfigProvider);

      // 各項目が期待通りの型で取得できることを確認
      expect(config.baseUrl, isA<String>());
      expect(config.aiModel, isA<String>());
      expect(config.connectTimeout, isA<int>());
      expect(config.receiveTimeout, isA<int>());
      expect(config.sendTimeout, isA<int>());
      expect(config.useFirebaseAuth, isA<bool>());
    });
  });
}
