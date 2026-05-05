import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'env_config.g.dart';

/// JSON (dart-define-from-file) から取得した公開設定を保持するモデル。
class EnvConfigState {
  /// コンストラクタ
  const EnvConfigState({
    required this.baseUrl,
    required this.aiModel,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
    required this.useFirebaseAuth,
  });

  /// API ベース URL
  final String baseUrl;

  /// AI モデル名
  final String aiModel;

  /// 接続タイムアウト（秒）
  final int connectTimeout;

  /// 受信タイムアウト（秒）
  final int receiveTimeout;

  /// 送信タイムアウト（秒）
  final int sendTimeout;

  /// Firebase Auth を使用するかどうか
  final bool useFirebaseAuth;
}

/// JSON から読み込んだ環境設定を提供するプロバイダー。
@riverpod
EnvConfigState envConfig(Ref ref) {
  return const EnvConfigState(
    baseUrl: String.fromEnvironment('BASE_URL'),
    aiModel: String.fromEnvironment('AI_MODEL'),
    connectTimeout: int.fromEnvironment('CONNECT_TIMEOUT', defaultValue: 10),
    receiveTimeout: int.fromEnvironment('RECEIVE_TIMEOUT', defaultValue: 15),
    sendTimeout: int.fromEnvironment('SEND_TIMEOUT', defaultValue: 10),
    useFirebaseAuth: bool.fromEnvironment(
      'USE_FIREBASE_AUTH',
      defaultValue: true,
    ),
  );
}
