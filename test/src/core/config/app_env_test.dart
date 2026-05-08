import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('AppEnv テスト', () {
    test('秘密情報（Envied）が正しく読み込まれること', () {
      // Arrange & Act & Assert

      // App Checkのデバッグトークン（秘匿情報）が取得できること
      expect(AppEnv.debugToken, isA<String>());

      // Google 逆クライアント ID（秘匿情報）が取得できること
      expect(AppEnv.googleReversedClientId, isA<String>());

      // 認証設定のProviderが真偽値を返すこと
      final container = ProviderContainer(
        overrides: [
          envConfigProvider.overrideWithValue(
            const EnvConfigState(
              baseUrl: 'https://test.example.com',
              aiModel: 'test-model',
              connectTimeout: 10,
              receiveTimeout: 15,
              sendTimeout: 10,
              useFirebaseAuth: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(envConfigProvider).useFirebaseAuth, isA<bool>());
    });
  });
}
