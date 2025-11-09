// lib/src/core/network/dio_interceptor.dart
// 共通のDioインターセプタを定義

import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/network/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_interceptor.g.dart';

/// Dioインターセプタプロバイダ
@Riverpod(keepAlive: true)
InterceptorsWrapper dioInterceptor(Ref ref) {
  final logger = ref.read(loggerProvider);

  return InterceptorsWrapper(
    onRequest: (options, handler) {
      logger.i('➡️ [${options.method}] ${options.uri}');
      return handler.next(options);
    },
    onResponse: (response, handler) {
      logger.d(
        '✅ Response [${response.statusCode}] ${response.requestOptions.uri}',
      );
      return handler.next(response);
    },
    onError: (DioException e, handler) {
      logger.e('❌ Error: ${e.message}');
      AppException exception;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          exception = const TimeoutException();
        case DioExceptionType.badResponse:
          exception = NetworkException(
            'サーバーエラーが発生しました',
            code: e.response?.statusCode,
          );
        case DioExceptionType.badCertificate:
        case DioExceptionType.cancel:
        case DioExceptionType.connectionError:
        case DioExceptionType.unknown:
          exception = UnknownException(e.message ?? '');
      }

      return handler.reject(
        DioException(
          requestOptions: e.requestOptions,
          error: exception,
        ),
      );
    },
  );
}
