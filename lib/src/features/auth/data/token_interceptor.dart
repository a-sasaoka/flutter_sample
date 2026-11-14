import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/core/network/request_auth_pin.dart';
import 'package:flutter_sample/src/core/utils/jwt_utils.dart';
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

  /// 同一ユーザーで同時実行されるリフレッシュ処理を1つにまとめるための Future マップ
  final Map<String?, Future<bool>> _refreshFutures = {};

  /// 現在の認証ユーザーが [expectedUserId] と一致していることを検証してトークンを返す
  Future<String?> _resolveVerifiedTokenForUser(String expectedUserId) async {
    final userIdBefore = await _storage.getUserId();
    if (userIdBefore != expectedUserId) {
      return null;
    }

    final token = await _storage.getAccessToken();
    if (token == null) {
      return null;
    }

    final userIdAfter = await _storage.getUserId();
    if (userIdAfter != expectedUserId) {
      return null;
    }

    final tokenUserId = JwtUtils.getUserId(token);
    if (tokenUserId != null && tokenUserId != expectedUserId) {
      return null;
    }

    return token;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final authPin = options.extra[RequestAuthPin.extraKey] as RequestAuthPin?;
    if (authPin != null) {
      // 既に送信元ユーザーの認証ヘッダーが固定済み（404後のPOST等）なら再取得せず維持する
      if (authPin.authorizationHeader case final pinnedHeader?) {
        options.headers['Authorization'] = pinnedHeader;
        handler.next(options);
        return;
      }

      final token = await _resolveVerifiedTokenForUser(authPin.expectedUserId);
      if (token == null) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: StateError(
              'Authenticated user mismatch for expected user: '
              '${authPin.expectedUserId}',
            ),
          ),
        );
        return;
      }

      final pinnedHeader = 'Bearer $token';
      authPin.authorizationHeader = pinnedHeader;
      options.headers['Authorization'] = pinnedHeader;
      handler.next(options);
      return;
    }

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
      final authPin =
          err.requestOptions.extra[RequestAuthPin.extraKey] as RequestAuthPin?;
      final currentUserId = await _storage.getUserId();
      if (authPin != null && currentUserId != authPin.expectedUserId) {
        handler.next(err);
        return;
      }

      final success = await _refreshTokens(currentUserId);

      if (success) {
        final newToken = authPin != null
            ? await _resolveVerifiedTokenForUser(authPin.expectedUserId)
            : await _storage.getAccessToken();
        if (authPin != null && newToken == null) {
          handler.next(err);
          return;
        }

        // 新しいトークンを取得してヘッダー（および共有コンテキスト）を更新
        final newAuthHeader = 'Bearer $newToken';
        if (authPin != null) {
          authPin.authorizationHeader = newAuthHeader;
        }
        err.requestOptions.headers['Authorization'] = newAuthHeader;

        // リトライ用のDioでリクエストを再実行
        try {
          final retryResponse = await _baseDio.fetch<dynamic>(
            err.requestOptions,
          );
          return handler.resolve(retryResponse);
        } on DioException catch (retryError) {
          if (retryError.error is AppException) {
            // baseDioのDioInterceptorが変換済みのAppExceptionは再ラップさせずそのまま拒否する
            return handler.reject(retryError);
          }
          return handler.next(retryError);
        }
      }
    }
    // 401以外、またはリフレッシュ失敗時はそのままエラーを流す
    handler.next(err);
  }

  /// トークンのリフレッシュを実行する（同一ユーザーの同時呼び出し時は1つに統合）
  Future<bool> _refreshTokens(String? userId) async {
    // すでに同一ユーザー向けの他リクエストがリフレッシュ中なら、その完了を待つ
    if (_refreshFutures[userId] case final future?) {
      return await future;
    }

    // 新規にリフレッシュ処理を開始
    final future = _executeRefresh();
    _refreshFutures[userId] = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshFutures[userId], future)) {
        unawaited(_refreshFutures.remove(userId));
      }
    }
  }

  Future<bool> _executeRefresh() async {
    try {
      return await _refreshCallback();
    } on Exception catch (_) {
      // リフレッシュ自体が例外（タイムアウト等）で失敗した場合は false を返す
      // これにより、元の 401 エラーが handler.next(err) へ渡される
      return false;
    }
  }
}
