import 'package:envied/envied.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';

part 'app_env.g.dart';

/// `.env.{environment}` ファイルを読み込む設定クラス。
/// 例: .env.local, .env.dev, .env.stg, .env.prod
///
/// このクラスは秘密情報（APIキー、シークレット等）の難読化・管理のみを担当します。
/// 公開設定は [EnvConfigState] を参照してください。
@Envied(
  path: '.env.local', // デフォルト
  obfuscate: true, // 値を暗号化してコードに埋め込む
)
abstract class AppEnv {
  /// App Checkのデバッグ用トークン（秘匿情報）
  @EnviedField(varName: 'DEBUG_TOKEN')
  static final String debugToken = _AppEnv.debugToken;

  /// iOS 用の Google 逆クライアント ID（個人の環境に紐づく識別子）
  @EnviedField(varName: 'GOOGLE_REVERSED_CLIENT_ID')
  static final String googleReversedClientId = _AppEnv.googleReversedClientId;
}
