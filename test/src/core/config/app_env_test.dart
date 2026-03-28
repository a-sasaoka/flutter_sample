import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnv テスト', () {
    test('環境変数が自動生成ファイル(.g.dart)から正しく読み込まれ、型やフォーマットが期待通りであること', () {
      // Arrange & Act & Assert
      // 静的プロパティにアクセスし、値が読み込めること（クラッシュしないこと）と型を検証します。

      // 文字列系の検証
      expect(AppEnv.flavor, isA<String>());
      expect(AppEnv.flavor, isNotEmpty, reason: 'FLAVORが空です');

      expect(AppEnv.appName, isA<String>());
      expect(AppEnv.appName, isNotEmpty, reason: 'APP_NAMEが空です');

      expect(AppEnv.appId, isA<String>());
      expect(AppEnv.appId, isNotEmpty, reason: 'APP_IDが空です');

      expect(AppEnv.baseUrl, isA<String>());
      expect(AppEnv.baseUrl, isNotEmpty, reason: 'BASE_URLが空です');
      expect(
        AppEnv.baseUrl,
        anyOf(startsWith('http://'), startsWith('https://')),
        reason: 'BASE_URLはhttpまたはhttpsから始まる必要があります',
      );

      // 数値系（タイムアウト設定）の検証
      expect(AppEnv.connectTimeout, isA<int>());
      expect(
        AppEnv.connectTimeout,
        greaterThan(0),
        reason: 'CONNECT_TIMEOUTは0より大きい必要があります',
      );

      expect(AppEnv.receiveTimeout, isA<int>());
      expect(
        AppEnv.receiveTimeout,
        greaterThan(0),
        reason: 'RECEIVE_TIMEOUTは0より大きい必要があります',
      );

      expect(AppEnv.sendTimeout, isA<int>());
      expect(
        AppEnv.sendTimeout,
        greaterThan(0),
        reason: 'SEND_TIMEOUTは0より大きい必要があります',
      );

      // 真偽値系の検証
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(useFirebaseAuthProvider), isA<bool>());

      // その他の文字列（空文字も許容される可能性があるものは isA<String> のみ）
      expect(AppEnv.debugToken, isA<String>());

      expect(AppEnv.aiModel, isA<String>());
      expect(AppEnv.aiModel, isNotEmpty, reason: 'AI_MODELが空です');
    });
  });
}
