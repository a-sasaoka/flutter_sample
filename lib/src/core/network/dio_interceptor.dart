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
        DioExceptionType.sendTimeout => const TimeoutException(),
        DioExceptionType.badResponse => NetworkException(
          statusCode: e.response?.statusCode,
        ),
        DioExceptionType.badCertificate ||
        DioExceptionType.cancel ||
        DioExceptionType.connectionError ||
        DioExceptionType.unknown => UnknownException(message: e.message),
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
