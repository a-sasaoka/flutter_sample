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

  /// Firebase Android API Key
  @EnviedField(varName: 'FIREBASE_ANDROID_API_KEY')
  static final String firebaseAndroidApiKey = _AppEnv.firebaseAndroidApiKey;

  /// Firebase Android APP ID
  @EnviedField(varName: 'FIREBASE_ANDROID_APP_ID')
  static final String firebaseAndroidAppId = _AppEnv.firebaseAndroidAppId;

  /// Firebase Android MESSAGING SENDER ID
  @EnviedField(varName: 'FIREBASE_ANDROID_MSG_SENDER_ID')
  static final String firebaseAndroidMessagingSenderId =
      _AppEnv.firebaseAndroidMessagingSenderId;

  /// Firebase Android PROJECT ID
  @EnviedField(varName: 'FIREBASE_ANDROID_PROJECT_ID')
  static final String firebaseAndroidProjectId =
      _AppEnv.firebaseAndroidProjectId;

  /// Firebase Android STORAGE BUCKET
  @EnviedField(varName: 'FIREBASE_ANDROID_STORAGE_BUCKET')
  static final String firebaseAndroidStorageBucket =
      _AppEnv.firebaseAndroidStorageBucket;

  /// Firebase iOS API Key
  @EnviedField(varName: 'FIREBASE_IOS_API_KEY')
  static final String firebaseIosApiKey = _AppEnv.firebaseIosApiKey;

  /// Firebase iOS APP ID
  @EnviedField(varName: 'FIREBASE_IOS_APP_ID')
  static final String firebaseIosAppId = _AppEnv.firebaseIosAppId;

  /// Firebase iOS MESSAGING SENDER ID
  @EnviedField(varName: 'FIREBASE_IOS_MSG_SENDER_ID')
  static final String firebaseIosMessagingSenderId =
      _AppEnv.firebaseIosMessagingSenderId;

  /// Firebase iOS PROJECT ID
  @EnviedField(varName: 'FIREBASE_IOS_PROJECT_ID')
  static final String firebaseIosProjectId = _AppEnv.firebaseIosProjectId;

  /// Firebase iOS STORAGE BUCKET
  @EnviedField(varName: 'FIREBASE_IOS_STORAGE_BUCKET')
  static final String firebaseIosStorageBucket =
      _AppEnv.firebaseIosStorageBucket;

  /// Firebase iOS BUNDLE ID
  @EnviedField(varName: 'FIREBASE_IOS_BUNDLE_ID')
  static final String firebaseIosBundleId = _AppEnv.firebaseIosBundleId;

  /// 認証設定
  @EnviedField(varName: 'USE_FIREBASE_AUTH')
  static final bool useFirebaseAuth = _AppEnv.useFirebaseAuth;

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
