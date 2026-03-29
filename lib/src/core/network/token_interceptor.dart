import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/storage/token_storage.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_interceptor.g.dart';

// coverage:ignore-start
/// テストで Notifier の内部構造 (_element) によるエラーを回避するため、
/// Notifier インスタンスを直接提供するだけの Provider を定義します。
/// これにより、テスト時は単なる Mock オブジェクトに差し替え可能になります。
@Riverpod(keepAlive: true)
TokenStorage tokenStorageInternal(Ref ref) {
  return ref.watch(tokenStorageProvider);
}

/// テストで Notifier の内部構造 (_element) によるエラーを回避するため、
/// Notifier インスタンスを直接提供するだけの Provider を定義します。
/// これにより、テスト時は単なる Mock オブジェクトに差し替え可能になります。
@Riverpod(keepAlive: true)
AuthRepository authRepositoryInternal(Ref ref) {
  return ref.watch(authRepositoryProvider.notifier);
}

/// 再リクエスト（リトライ）用のDioインスタンスを提供するProvider
/// テスト時にモックへ差し替え可能にするために切り出し
@Riverpod(keepAlive: true)
Dio retryDio(Ref ref) {
  return Dio();
}
// coverage:ignore-end

/// トークンを自動で付与・更新するDioのインターセプター
@Riverpod(keepAlive: true)
InterceptorsWrapper tokenInterceptor(Ref ref) {
  return InterceptorsWrapper(
    onRequest: (options, handler) async {
      final storage = ref.read(tokenStorageInternalProvider);
      final token = await storage.getAccessToken();

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (DioException e, handler) async {
      if (e.response?.statusCode == 401) {
        final authRepo = ref.read(authRepositoryInternalProvider);
        final refreshed = await authRepo.refreshToken();

        if (refreshed) {
          final storage = ref.read(tokenStorageInternalProvider);
          final newToken = await storage.getAccessToken();

          e.requestOptions.headers['Authorization'] = 'Bearer $newToken';

          final dio = ref.read(retryDioProvider);
          try {
            final retryResponse = await dio.fetch<Map<String, dynamic>>(
              e.requestOptions,
            );
            return handler.resolve(retryResponse);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        }
      }
      return handler.next(e);
    },
  );
}
