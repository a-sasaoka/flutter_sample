import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_interceptor.g.dart';

/// Dioインターセプタプロバイダ
@Riverpod(keepAlive: true)
InterceptorsWrapper dioInterceptor(Ref ref) {
  final logger = ref.watch(loggerProvider);

  return InterceptorsWrapper(
    onRequest: (options, handler) {
      logger.info('➡️ [${options.method}] ${options.uri}');
      return handler.next(options);
    },
    onResponse: (response, handler) {
      logger.debug(
        '✅ Response [${response.statusCode}] ${response.requestOptions.uri}',
      );
      return handler.next(response);
    },
    onError: (e, handler) {
      logger.error('❌ Error: ${e.message}');

      // エラーの種類に応じて例外を生成する
      final exception = switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => const AppException.timeout(),
        DioExceptionType.badResponse => _mapResponseError(e),
        DioExceptionType.cancel => const AppException.cancel(),
        DioExceptionType.connectionError => const AppException.network(),
        DioExceptionType.badCertificate || DioExceptionType.unknown =>
          AppException.unknown(message: e.message, error: e.error),
      };

      return handler.reject(
        DioException(
          requestOptions: e.requestOptions,
          error: exception,
        ),
      );
    },
  );
}

/// レスポンスエラー（400-500系）の変換
AppException _mapResponseError(DioException e) {
  final statusCode = e.response?.statusCode;
  final message = e.message;

  if (statusCode == null) return AppException.unknown(message: message);

  return switch (statusCode) {
    401 => const AppException.unauthenticated(),
    403 => const AppException.unauthorized(),
    >= 400 && < 500 => AppException.badRequest(statusCode: statusCode),
    >= 500 => AppException.server(statusCode: statusCode),
    _ => AppException.unknown(message: message),
  };
}
