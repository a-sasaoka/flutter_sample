import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_interceptor.g.dart';

/// トークンのリフレッシュを実行し、成功したかどうかを返す関数の型
typedef TokenRefreshCallback = Future<bool> Function();

/// [TokenRefreshCallback] を提供するプロバイダ
///
/// デフォルトでは `UnimplementedError` を投げます。
/// アプリ起動時の `ProviderScope` (overrides) にて、
/// 認証機能のリフレッシュ処理（`authRepositoryProvider.refreshToken`）でオーバーライドして使用してください
@Riverpod(keepAlive: true)
TokenRefreshCallback tokenRefreshCallback(Ref ref) {
  throw UnimplementedError(
    'Please override it in the ProviderScope of the App layer',
  );
}

// coverage:ignore-start
/// テストで Notifier の内部構造 (_element) によるエラーを回避するため、
/// Notifier インスタンスを直接提供するだけの Provider を定義します。
@Riverpod(keepAlive: true)
TokenStorage tokenStorageInternal(Ref ref) {
  return ref.watch(tokenStorageProvider);
}
// coverage:ignore-end

/// トークンを自動で付与・更新するDioのインターセプター
@Riverpod(keepAlive: true)
Interceptor tokenInterceptor(Ref ref) {
  return _TokenInterceptor(
    storage: ref.watch(tokenStorageInternalProvider),
    baseDio: ref.watch(baseDioProvider),
    refreshCallback: ref.watch(tokenRefreshCallbackProvider),
  );
}

/// トークン制御の実装クラス
class _TokenInterceptor extends Interceptor {
  _TokenInterceptor({
    required TokenStorage storage,
    required Dio baseDio,
    required TokenRefreshCallback refreshCallback,
  }) : _storage = storage,
       _baseDio = baseDio,
       _refreshCallback = refreshCallback;

  final TokenStorage _storage;
  final Dio _baseDio;
  final TokenRefreshCallback _refreshCallback;

  /// 同時実行されるリフレッシュ処理を1つにまとめるための Future
  Future<bool>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 401 Unauthorized (認証切れ) の場合にリフレッシュを試みる
    if (err.response?.statusCode == 401) {
      final success = await _refreshTokens();

      if (success) {
        // 新しいトークンを取得してヘッダーを更新
        final newToken = await _storage.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

        // リトライ用のDioでリクエストを再実行
        try {
          final retryResponse = await _baseDio.fetch<dynamic>(
            err.requestOptions,
          );
          return handler.resolve(retryResponse);
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      }
    }
    // 401以外、またはリフレッシュ失敗時はそのままエラーを流す
    handler.next(err);
  }

  /// トークンのリフレッシュを実行する（同時呼び出し時は1つに統合）
  Future<bool> _refreshTokens() async {
    // すでに他のリクエストがリフレッシュ中なら、その完了を待つ
    if (_refreshFuture case final Future<bool> future) {
      return future;
    }

    try {
      // 新規にリフレッシュ処理を開始
      final future = _refreshCallback();
      _refreshFuture = future;
      return await future;
    } on Exception catch (_) {
      // リフレッシュ自体が例外（タイムアウト等）で失敗した場合は false を返す
      // これにより、元の 401 エラーが handler.next(err) へ渡される
      return false;
    } finally {
      // 完了（成功・失敗問わず）したらリセット
      _refreshFuture = null;
    }
  }
}
