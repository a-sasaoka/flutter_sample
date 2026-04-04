import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/storage/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_interceptor.g.dart';

/// トークンのリフレッシュを実行し、成功したかどうかを返す関数の型
///
/// Core層が特定の機能（AuthRepository等）に依存しないよう、
/// 関数のみを受け取る設計（依存関係の逆転）にしています
typedef TokenRefreshCallback = Future<bool> Function();

/// [TokenRefreshCallback] を提供するプロバイダ
///
/// Core層では具体的な実装を持たないため、デフォルトでは `UnimplementedError` を投げます。
/// アプリ起動時の最上位の `ProviderScope` (overrides) にて、
/// Feature層のリフレッシュ処理（例: authRepositoryProvider の refreshToken メソッド）
/// でオーバーライドして使用してください
@Riverpod(keepAlive: true)
TokenRefreshCallback tokenRefreshCallback(Ref ref) {
  throw UnimplementedError(
    'Please override it in the ProviderScope of the App layer',
  );
}

// coverage:ignore-start
/// テストで Notifier の内部構造 (_element) によるエラーを回避するため、
/// Notifier インスタンスを直接提供するだけの Provider を定義します。
/// これにより、テスト時は単なる Mock オブジェクトに差し替え可能になります。
@Riverpod(keepAlive: true)
TokenStorage tokenStorageInternal(Ref ref) {
  return ref.watch(tokenStorageProvider);
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
        final refreshTokenFn = ref.read(tokenRefreshCallbackProvider);
        final refreshed = await refreshTokenFn();

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
