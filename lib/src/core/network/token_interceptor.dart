import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
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
///
/// メインの `dioProvider` と同じタイムアウト設定を適用します。
@Riverpod(keepAlive: true)
Dio retryDio(Ref ref) {
  final config = ref.watch(envConfigProvider);
  return Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: config.connectTimeout),
      receiveTimeout: Duration(seconds: config.receiveTimeout),
      sendTimeout: Duration(seconds: config.sendTimeout),
    ),
  );
}
// coverage:ignore-end

/// トークンを自動で付与・更新するDioのインターセプター
@Riverpod(keepAlive: true)
Interceptor tokenInterceptor(Ref ref) {
  return _TokenInterceptor(
    storage: ref.watch(tokenStorageInternalProvider),
    retryDio: ref.watch(retryDioProvider),
    refreshCallback: ref.watch(tokenRefreshCallbackProvider),
  );
}

/// トークン制御の実装クラス
class _TokenInterceptor extends Interceptor {
  _TokenInterceptor({
    required TokenStorage storage,
    required Dio retryDio,
    required TokenRefreshCallback refreshCallback,
  }) : _storage = storage,
       _retryDio = retryDio,
       _refreshCallback = refreshCallback;

  final TokenStorage _storage;
  final Dio _retryDio;
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
          final retryResponse = await _retryDio.fetch<dynamic>(
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
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    // 新規にリフレッシュ処理を開始
    _refreshFuture = _refreshCallback();

    try {
      final result = await _refreshFuture!;
      return result;
    } finally {
      // 完了（成功・失敗問わず）したらリセット
      _refreshFuture = null;
    }
  }
}
