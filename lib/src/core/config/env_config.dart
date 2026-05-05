import 'package:freezed_annotation/freezed_annotation.dart';
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
}

/// JSON から読み込んだ環境設定を提供するプロバイダー。
@riverpod
EnvConfigState envConfig(Ref ref) {
  return const EnvConfigState(
    baseUrl: String.fromEnvironment(
      'BASE_URL',
      defaultValue: 'https://jsonplaceholder.typicode.com',
    ),
    aiModel: String.fromEnvironment(
      'AI_MODEL',
      defaultValue: 'gemini-2.5-flash',
    ),
    connectTimeout: int.fromEnvironment('CONNECT_TIMEOUT', defaultValue: 10),
    receiveTimeout: int.fromEnvironment('RECEIVE_TIMEOUT', defaultValue: 15),
    sendTimeout: int.fromEnvironment('SEND_TIMEOUT', defaultValue: 10),
    useFirebaseAuth: bool.fromEnvironment(
      'USE_FIREBASE_AUTH',
      defaultValue: true,
    ),
  );
}
