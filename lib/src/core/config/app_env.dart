// Enviedを使って環境ごとに設定値を安全に読み込む仕組み。

import 'package:envied/envied.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  /// FLAVOR
  @EnviedField(varName: 'FLAVOR')
  static final String flavor = _AppEnv.flavor;

  /// アプリケーション名
  @EnviedField(varName: 'APP_NAME')
  static final String appName = _AppEnv.appName;

  /// アプリケーションID
  @EnviedField(varName: 'APP_ID')
  static final String appId = _AppEnv.appId;

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

  /// 認証設定
  @EnviedField(varName: 'USE_FIREBASE_AUTH')
  static final bool useFirebaseAuth = _AppEnv.useFirebaseAuth;

  /// App Checkのデバッグ用トークン
  @EnviedField(varName: 'DEBUG_TOKEN')
  static final String debugToken = _AppEnv.debugToken;

  /// AIモデル
  @EnviedField(varName: 'AI_MODEL')
  static final String aiModel = _AppEnv.aiModel;
}

/// 認証設定をRiverpodで提供
@riverpod
bool useFirebaseAuth(Ref ref) => AppEnv.useFirebaseAuth;
