import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/network/dio_interceptor.dart';
import 'package:flutter_sample/src/core/network/token_interceptor.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'api_client.g.dart';

/// 共通Dioインスタンスを提供するProvider
///
/// - Base URLやタイムアウトを設定
/// - インターセプタでログ出力
/// - 必要に応じてトークン認証もここで実装可能
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.baseUrl,
      connectTimeout: Duration(seconds: AppEnv.connectTimeout),
      receiveTimeout: Duration(seconds: AppEnv.receiveTimeout),
      sendTimeout: Duration(seconds: AppEnv.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  // トークン付与・更新
  dio.interceptors.add(ref.watch(tokenInterceptorProvider));

  // ログ出力・例外処理
  dio.interceptors.add(ref.watch(dioInterceptorProvider));

  // 開発時のみリクエスト・レスポンスログを出力
  if (kDebugMode) {
    dio.interceptors.add(
      TalkerDioLogger(
        talker: ref.watch(loggerProvider),
        settings: TalkerDioLoggerSettings(
          printRequestHeaders: true,
          errorPen: AnsiPen()..red(),
          requestPen: AnsiPen()..yellow(),
          responsePen: AnsiPen()..green(),
        ),
      ),
    );
  }

  return dio;
}

/// API呼び出し用の共通クライアントクラス
///
/// 各リポジトリやデータソース層から利用します。
class ApiClient {
  /// コンストラクタ
  ApiClient._(this._dio);

  final Dio _dio;

  /// GETリクエスト
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// POSTリクエスト
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// PUTリクエスト
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// DELETEリクエスト
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}

/// ApiClient を Riverpod 経由で提供する Provider
///
/// `ref.watch(apiClientProvider)` でどこからでも取得可能。
@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final dioInstance = ref.watch(dioProvider);
  return ApiClient._(dioInstance);
}
