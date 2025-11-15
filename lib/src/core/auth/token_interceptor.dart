import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/auth/auth_repository.dart';
import 'package:flutter_sample/src/core/auth/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_interceptor.g.dart';

/// トークンを自動で付与・更新するDioのインターセプター
@Riverpod(keepAlive: true)
InterceptorsWrapper tokenInterceptor(Ref ref) {
  final storage = ref.read(tokenStorageProvider.notifier);

  return InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (DioException e, handler) async {
      if (e.response?.statusCode == 401) {
        final refreshed = await ref
            .read(authRepositoryProvider.notifier)
            .refreshToken();
        if (refreshed) {
          final newToken = await storage.getAccessToken();
          e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final dio = Dio();
          final retryResponse = await dio.fetch<Map<String, dynamic>>(
            e.requestOptions,
          );
          return handler.resolve(retryResponse);
        }
      }
      return handler.next(e);
    },
  );
}
