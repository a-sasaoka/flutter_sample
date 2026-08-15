import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'env_config.freezed.dart';
part 'env_config.g.dart';

/// JSON (dart-define-from-file) から取得した公開設定を保持するモデル。
@freezed
sealed class EnvConfigState with _$EnvConfigState {
  /// コンストラクタ
  const factory EnvConfigState({
    /// API ベース URL
    required String baseUrl,

    /// AI モデル名
    required String aiModel,

    /// 接続タイムアウト（秒）
    required int connectTimeout,

    /// 受信タイムアウト（秒）
    required int receiveTimeout,

    /// 送信タイムアウト（秒）
    required int sendTimeout,

    /// Firebase Auth を使用するかどうか
    required bool useFirebaseAuth,

    /// Agent Platform (旧 Vertex AI) を使用するかどうか (false の場合は Google AI / Developer API)
    required bool useAgentPlatform,

    /// Google Directions API の URL
    required String googleDirectionsApiUrl,
  }) = _EnvConfigState;

  const EnvConfigState._();

  /// 設定内容をデバッグ用の文字列として整形して返します。
  String getDebugReport(PackageInfo packageInfo) =>
      '''
📱 App Name          : ${packageInfo.appName}
🆔 Package Name      : ${packageInfo.packageName}
✨ Version           : ${packageInfo.version} (${packageInfo.buildNumber})
📍 API Base URL      : $baseUrl
🗺️ Directions API    : $googleDirectionsApiUrl
🤖 AI Model          : $aiModel
⏱️ Timeouts (C/R/S)  : $connectTimeout / $receiveTimeout / $sendTimeout
🔥 Firebase Auth     : $useFirebaseAuth
🤖 Use Agent Platform: $useAgentPlatform''';
}

/// デフォルトの API ベース URL（サンプルの動作確認用）
const defaultBaseUrl = 'https://jsonplaceholder.typicode.com';

/// デフォルトの Google Routes API URL
const defaultGoogleDirectionsApiUrl =
    'https://routes.googleapis.com/directions/v2:computeRoutes';

/// デフォルトの AI モデル名
const defaultAiModel = 'gemini-3.5-flash-lite';

/// デフォルトの接続タイムアウト（秒）
const defaultConnectTimeout = 10;

/// デフォルトの受信タイムアウト（秒）
const defaultReceiveTimeout = 15;

/// デフォルトの送信タイムアウト（秒）
const defaultSendTimeout = 10;

/// デフォルトの Firebase Auth を使用するかどうか
const defaultUseFirebaseAuth = true;

/// デフォルトの Agent Platform を使用するかどうか
const defaultUseAgentPlatform = true;

/// JSON から読み込んだ環境設定を提供するプロバイダー。
@Riverpod(keepAlive: true)
EnvConfigState envConfig(Ref ref) {
  return const EnvConfigState(
    baseUrl: String.fromEnvironment(
      'BASE_URL',
      defaultValue: defaultBaseUrl,
    ),
    aiModel: String.fromEnvironment(
      'AI_MODEL',
      defaultValue: defaultAiModel,
    ),
    connectTimeout: int.fromEnvironment(
      'CONNECT_TIMEOUT',
      defaultValue: defaultConnectTimeout,
    ),
    receiveTimeout: int.fromEnvironment(
      'RECEIVE_TIMEOUT',
      defaultValue: defaultReceiveTimeout,
    ),
    sendTimeout: int.fromEnvironment(
      'SEND_TIMEOUT',
      defaultValue: defaultSendTimeout,
    ),
    useFirebaseAuth: bool.fromEnvironment(
      'USE_FIREBASE_AUTH',
      defaultValue: defaultUseFirebaseAuth,
    ),
    useAgentPlatform: bool.fromEnvironment(
      'USE_AGENT_PLATFORM',
      defaultValue: defaultUseAgentPlatform,
    ),
    googleDirectionsApiUrl: String.fromEnvironment(
      'GOOGLE_DIRECTIONS_API_URL',
      defaultValue: defaultGoogleDirectionsApiUrl,
    ),
  );
}
