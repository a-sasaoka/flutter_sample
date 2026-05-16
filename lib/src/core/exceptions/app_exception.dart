import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_exception.freezed.dart';

/// アプリケーション共通の例外クラス (Union型)
@freezed
sealed class AppException with _$AppException implements Exception {
  /// ネットワーク接続エラー (オフラインなど)
  const factory AppException.network({
    String? message,
  }) = NetworkException;

  /// サーバーエラー (500系)
  const factory AppException.server({
    int? statusCode,
    String? message,
  }) = ServerException;

  /// クライアントエラー (400系, validation等)
  const factory AppException.badRequest({
    int? statusCode,
    String? message,
  }) = BadRequestException;

  /// 認証エラー (401: 未ログイン, セッション切れ)
  const factory AppException.unauthenticated({
    String? message,
  }) = UnauthenticatedException;

  /// 認可エラー (403: 権限不足)
  const factory AppException.unauthorized({
    String? message,
  }) = UnauthorizedException;

  /// 通信タイムアウト
  const factory AppException.timeout({
    String? message,
  }) = TimeoutException;

  /// データ解析エラー (レスポンスが空、不正なJSONなど)
  const factory AppException.dataParse({
    String? message,
  }) = DataParseException;

  /// データベースエラー (ローカルDB操作失敗)
  const factory AppException.database({
    String? message,
    Object? error,
  }) = DatabaseException;

  /// キャンセル (リクエストの中断)
  const factory AppException.cancel({
    String? message,
  }) = CancelException;

  /// その他の予期せぬエラー
  const factory AppException.unknown({
    String? message,
    Object? error,
  }) = UnknownException;
}

/// AppException の拡張メソッド
extension AppExceptionX on AppException {
  /// ステータスコードを取得する (存在する場合のみ)
  int? get statusCode => whenOrNull(
    server: (code, _) => code,
    badRequest: (code, _) => code,
  );

  /// 内部エラーオブジェクトを取得する (UnknownException または DatabaseException の場合のみ)
  Object? get error => whenOrNull(
    database: (_, err) => err,
    unknown: (_, err) => err,
  );
}
