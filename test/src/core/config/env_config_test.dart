import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('EnvConfig テスト', () {
    test('envConfigProvider がデフォルト値を正しく返すこと', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(envConfigProvider);

      // 環境変数が指定されていないテスト実行時、デフォルト値が返ることを確認
      expect(config.baseUrl, defaultBaseUrl);
      expect(config.aiModel, defaultAiModel);
      expect(config.connectTimeout, defaultConnectTimeout);
      expect(config.receiveTimeout, defaultReceiveTimeout);
      expect(config.sendTimeout, defaultSendTimeout);
      expect(config.useFirebaseAuth, defaultUseFirebaseAuth);
    });

    test('getDebugReport が正しいフォーマットで文字列を生成すること', () {
      const config = EnvConfigState(
        baseUrl: 'https://test.com',
        aiModel: 'test-model',
        connectTimeout: 1,
        receiveTimeout: 2,
        sendTimeout: 3,
        useFirebaseAuth: false,
      );

      final packageInfo = PackageInfo(
        appName: 'TestApp',
        packageName: 'com.test.app',
        version: '1.0.0',
        buildNumber: '1',
      );

      final report = config.getDebugReport(packageInfo);

      expect(report, contains('📱 App Name          : TestApp'));
      expect(report, contains('🆔 Package Name      : com.test.app'));
      expect(report, contains('✨ Version           : 1.0.0 (1)'));
      expect(report, contains('📍 API Base URL      : https://test.com'));
      expect(report, contains('🤖 AI Model          : test-model'));
      expect(report, contains('⏱️ Timeouts (C/R/S)  : 1 / 2 / 3'));
      expect(report, contains('🔥 Firebase Auth     : false'));
    });
  });
}
