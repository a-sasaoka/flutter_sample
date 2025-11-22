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
  const AppException(this.type, {this.code});

  /// 例外の種類
  final ExceptionType type;

  /// エラーコード（任意）
  final int? code;

  /// 多言語化用のメッセージキー
  String get messageKey {
    switch (type) {
      case ExceptionType.network:
        return 'errorNetwork';
      case ExceptionType.timeout:
        return 'errorTimeout';
      case ExceptionType.unknown:
        return 'errorUnknown';
    }
  }

  @override
  String toString() => type.name;
}

/// ネットワーク関連の例外
class NetworkException extends AppException {
  /// コンストラクタ
  const NetworkException({this.statusCode, int? code})
    : super(ExceptionType.network, code: code);

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
}

/// タイムアウト
class TimeoutException extends AppException {
  /// コンストラクタ
  const TimeoutException() : super(ExceptionType.timeout);
}

/// 不明なエラー
class UnknownException extends AppException {
  /// コンストラクタ
  const UnknownException({this.message}) : super(ExceptionType.unknown);

  /// 任意のメッセージ
  final String? message;
}
