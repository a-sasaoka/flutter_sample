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
  }) = _EnvConfigState;

  const EnvConfigState._();

  /// 設定内容をデバッグ用の文字列として整形して返します。
  String getDebugReport(PackageInfo packageInfo) =>
      '''
📱 App Name          : ${packageInfo.appName}
🆔 Package Name      : ${packageInfo.packageName}
✨ Version           : ${packageInfo.version} (${packageInfo.buildNumber})
📍 API Base URL      : $baseUrl
🤖 AI Model          : $aiModel
⏱️ Timeouts (C/R/S)  : $connectTimeout / $receiveTimeout / $sendTimeout
🔥 Firebase Auth     : $useFirebaseAuth''';
}

/// デフォルトの API ベース URL（サンプルの動作確認用）
const defaultBaseUrl = 'https://jsonplaceholder.typicode.com';

/// デフォルトの AI モデル名
const defaultAiModel = 'gemini-2.5-flash';

/// デフォルトの接続タイムアウト（秒）
const defaultConnectTimeout = 10;

/// デフォルトの受信タイムアウト（秒）
const defaultReceiveTimeout = 15;

/// デフォルトの送信タイムアウト（秒）
const defaultSendTimeout = 10;

/// デフォルトの Firebase Auth を使用するかどうか
const defaultUseFirebaseAuth = true;

/// JSON から読み込んだ環境設定を提供するプロバイダー。
@riverpod
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
  );
}
