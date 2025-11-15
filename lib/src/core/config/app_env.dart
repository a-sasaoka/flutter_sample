// Enviedを使って環境ごとに設定値を安全に読み込む仕組み。

import 'package:envied/envied.dart';

part 'app_env.g.dart';

/// `.env.{environment}` ファイルを読み込む設定クラス。
/// 例: .env.local, .env.dev, .env.stg, .env.prod
///
/// デフォルトは `.env.local`
@Envied(
  path: '.env.local', // デフォルト
  obfuscate: true, // 値を暗号化してコードに埋め込む
)
abstract class AppEnv {
  /// ベースURL
  @EnviedField(varName: 'BASE_URL')
  static final String baseUrl = _AppEnv.baseUrl;

  /// 接続タイムアウト（秒）
  @EnviedField(varName: 'CONNECT_TIMEOUT')
  static final int connectTimeout = _AppEnv.connectTimeout;

  /// 受信タイムアウト（秒）
  @EnviedField(varName: 'RECEIVE_TIMEOUT')
  static final int receiveTimeout = _AppEnv.receiveTimeout;

  /// 送信タイムアウト（秒）
  @EnviedField(varName: 'SEND_TIMEOUT')
  static final int sendTimeout = _AppEnv.sendTimeout;

  /// ================================
  /// 🌎 現在の実行環境（手動設定）
  /// ================================
  static const String environment = _envName;

  // 環境識別子
  static const String _envName = String.fromEnvironment(
    'FLUTTER_ENV',
    defaultValue: 'local',
  );
}
