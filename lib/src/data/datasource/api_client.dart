// lib/src/data/datasource/api_client.dart
// Dio + pretty_dio_logger + Riverpod構成
// API通信の共通設定を行うクライアントクラス

import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/auth/token_interceptor.dart';
import 'package:flutter_sample/src/core/config/app_env.dart';
import 'package:flutter_sample/src/core/network/dio_interceptor.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  dio.interceptors.add(ref.read(tokenInterceptorProvider));

  // ログ出力・例外処理
  dio.interceptors.add(ref.read(dioInterceptorProvider));

  // 開発時のみリクエスト・レスポンスログを出力
  dio.interceptors.add(
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
    ),
  );

  return dio;
}

/// API呼び出し用の共通クライアントクラス
///
/// 各リポジトリやデータソース層から利用します。
class ApiClient {
  /// コンストラクタ
  ApiClient(this._dio);

  final Dio _dio;

  /// GETリクエスト
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  /// POSTリクエスト
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
  }) {
    return _dio.post<T>(path, data: data);
  }

  /// PUTリクエスト
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
  }) {
    return _dio.put<T>(path, data: data);
  }

  /// DELETEリクエスト
  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.delete<T>(path, queryParameters: queryParameters);
  }
}

/// ApiClient を Riverpod 経由で提供する Provider
///
/// `ref.watch(apiClientProvider)` でどこからでも取得可能。
@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final dioInstance = ref.watch(dioProvider);
  return ApiClient(dioInstance);
}
