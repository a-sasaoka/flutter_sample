// API・通信系の共通例外クラス

/// 例外の種類を明示的に表す列挙型
enum ExceptionType {
  /// ネットワーク関連の例外
  network,

  /// タイムアウト
  timeout,

  /// 不明なエラー
  unknown,
}

/// アプリケーション共通の例外基底クラス
sealed class AppException implements Exception {
  const AppException(this.message, this.type, {this.code});

  /// エラーメッセージ
  final String message;

  /// 例外の種類
  final ExceptionType type;

  /// エラーコード（任意）
  final int? code;

  @override
  String toString() => '${type.name}: $message';
}

/// ネットワーク関連の例外
class NetworkException extends AppException {
  /// コンストラクタ
  const NetworkException(String message, {int? code})
    : super(message, ExceptionType.network, code: code);
}

/// タイムアウト
class TimeoutException extends AppException {
  /// コンストラクタ
  const TimeoutException() : super('通信がタイムアウトしました', ExceptionType.timeout);
}

/// 不明なエラー
class UnknownException extends AppException {
  /// コンストラクタ
  const UnknownException([String message = '予期しないエラーが発生しました'])
    : super(message, ExceptionType.unknown);
}
