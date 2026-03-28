// API・通信系の共通例外クラス

/// アプリケーション共通の例外基底クラス
sealed class AppException implements Exception {
  const AppException({this.code});

  /// エラーコード（任意）
  final int? code;

  /// 多言語化用のメッセージキー
  String get messageKey;
}

/// ネットワーク関連の例外
class NetworkException extends AppException {
  /// コンストラクタ
  const NetworkException({this.statusCode, super.code});

  /// ステータスコード（任意）
  final int? statusCode;

  @override
  String get messageKey {
    // 500番台はサーバーエラーとして扱う
    if (statusCode != null && statusCode! >= 500) {
      return 'errorServer';
    }
    return 'errorNetwork';
  }

  @override
  String toString() => 'NetworkException(statusCode: $statusCode, code: $code)';
}

/// タイムアウト
class TimeoutException extends AppException {
  /// コンストラクタ
  const TimeoutException({super.code});

  @override
  String get messageKey => 'errorTimeout';

  @override
  String toString() => 'TimeoutException(code: $code)';
}

/// 不明なエラー
class UnknownException extends AppException {
  /// コンストラクタ
  const UnknownException({this.message, super.code});

  /// 任意のメッセージ
  final String? message;

  @override
  String get messageKey => 'errorUnknown';

  @override
  String toString() => 'UnknownException(message: $message, code: $code)';
}
