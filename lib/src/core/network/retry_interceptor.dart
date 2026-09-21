import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/uuid_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:uuid/uuid.dart';

part 'retry_interceptor.g.dart';

/// [RetryInterceptor] を提供するプロバイダー
@Riverpod(keepAlive: true)
Interceptor retryInterceptor(Ref ref) {
  return RetryInterceptor(
    uuid: ref.watch(uuidProvider),
    talker: ref.watch(loggerProvider),
    retryDio: ref.watch(baseDioProvider),
  );
}

/// 通信瞬断・一時障害時の自動リトライおよびべき等性（Idempotency-Key）を制御するインターセプター
class RetryInterceptor extends Interceptor {
  /// コンストラクタ
  RetryInterceptor({
    required Uuid uuid,
    required Talker talker,
    required Dio retryDio,
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
  }) : _uuid = uuid,
       _talker = talker,
       _retryDio = retryDio;

  final Uuid _uuid;
  final Talker _talker;
  final Dio _retryDio;

  /// 最大リトライ回数
  final int maxRetries;

  /// 指数バックオフの初期待機時間
  final Duration initialDelay;

  /// べき等キーのヘッダー名
  static const idempotencyKeyHeader = 'Idempotency-Key';

  /// リトライ回数を追跡するための extra キー
  static const _retryCountKey = 'extra_retry_count';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();

    // POST, PUT, PATCH の通信において、まだ Idempotency-Key が未設定の場合は自動付与
    if (method == 'POST' || method == 'PUT' || method == 'PATCH') {
      if (!options.headers.containsKey(idempotencyKeyHeader)) {
        options.headers[idempotencyKeyHeader] = _uuid.v4();
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 1. リトライ対象のエラーでなければそのまま次へ流す
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final extra = err.requestOptions.extra;
    final currentRetry = extra[_retryCountKey] as int? ?? 0;

    // 2. 最大リトライ回数に達した場合は諦めてエラーを返却
    if (currentRetry >= maxRetries) {
      final statusCode = err.response?.statusCode;
      // 502, 503, 504 などのサーバー障害でリトライしきれなかった場合は Crashlytics に送信
      if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
        _talker.handle(
          err,
          err.stackTrace,
          '💥 [RetryInterceptor] サーバー障害（HTTP $statusCode）が解消せず、最大リトライ回数に達しました: '
          '[${err.requestOptions.method}] ${err.requestOptions.uri}',
        );
      } else {
        _talker.warning(
          '⚠️ [RetryInterceptor] 最大リトライ回数（$maxRetries回）に達したため再送を終了します: '
          '[${err.requestOptions.method}] ${err.requestOptions.uri}',
        );
      }
      return handler.next(err);
    }

    final nextRetry = currentRetry + 1;
    extra[_retryCountKey] = nextRetry;

    // 3. 指数バックオフ計算（1s -> 2s -> 4s）
    final delaySeconds = initialDelay.inSeconds * (1 << currentRetry);
    final delay = initialDelay == Duration.zero
        ? Duration.zero
        : Duration(seconds: delaySeconds);

    _talker.warning(
      '🔁 [RetryInterceptor] 一時的な通信エラーを検知しました。再送を試行します '
      '($nextRetry/$maxRetries回目, ${delay.inSeconds}秒待機): '
      '[${err.requestOptions.method}] ${err.requestOptions.uri}',
    );

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    // 4. 元のリクエストを引き継いで再送信
    try {
      final response = await _retryDio.fetch<dynamic>(err.requestOptions);
      _talker.info(
        '✅ [RetryInterceptor] 再送に成功しました ($nextRetry/$maxRetries回目): '
        '[${err.requestOptions.method}] ${err.requestOptions.uri}',
      );
      return handler.resolve(response);
    } on DioException catch (retryError) {
      // 再送時もエラーの場合は再帰的に次のリトライを試行
      return await onError(retryError, handler);
    } on Object catch (e, st) {
      // DioException 以外の予期せぬ例外が発生した場合は Crashlytics に送信して安全に終了
      _talker.handle(e, st, '💥 [RetryInterceptor] 再送処理中に予期せぬ例外が発生しました');
      return handler.next(err);
    }
  }

  /// リトライ対象のエラーかどうかを判定する
  bool _shouldRetry(DioException err) {
    // ユーザーキャンセルはリトライしない
    if (err.type == DioExceptionType.cancel) {
      return false;
    }

    // 接続タイムアウト、送受信タイムアウト、ネットワーク切断エラーは一時障害とみなしてリトライ
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // サーバーレスポンスエラーのうち、502/503/504 は一時障害とみなしてリトライ
    if (err.type == DioExceptionType.badResponse) {
      final statusCode = err.response?.statusCode;
      return statusCode == 502 || statusCode == 503 || statusCode == 504;
    }

    return false;
  }
}
