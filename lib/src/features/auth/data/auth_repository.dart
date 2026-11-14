import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/data/auth_session_lock.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'auth_repository.g.dart';

/// AuthRepository専用のAPIクライアント（無限ループを防ぐためトークンインターセプタを除外）
@Riverpod(keepAlive: true)
ApiClient authApiClient(Ref ref) {
  return DioApiClient(ref.watch(baseDioProvider));
}

/// 認証リポジトリ
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    api: ref.watch(authApiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    talker: ref.watch(loggerProvider),
    sessionLock: ref.watch(authSessionLockProvider),
  );
}

/// 認証リポジトリの実装クラス
class AuthRepository {
  /// コンストラクタ
  AuthRepository({
    required this.api,
    required this.tokenStorage,
    required this.talker,
    AuthSessionLock? sessionLock,
  }) : _sessionLock = sessionLock ?? AuthSessionLock();

  /// APIクライアント
  final ApiClient api;

  /// トークンストレージ
  final TokenStorage tokenStorage;

  /// ロガー
  final Talker talker;

  final AuthSessionLock _sessionLock;

  /// ログインAPIを呼び出し、トークンを保存する
  Future<void> login(String email, String password) async {
    final response = await api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    if (response.data case {
      'access_token': final String access,
      'refresh_token': final String refresh,
    }) {
      await _sessionLock.synchronized(
        () =>
            tokenStorage.saveTokens(accessToken: access, refreshToken: refresh),
      );
    } else {
      talker.handle(
        const AppException.dataParse(),
        StackTrace.current,
        'Failed to parse login response: Missing or invalid tokens',
      );
      throw const AppException.dataParse();
    }
  }

  /// リフレッシュトークンAPIを呼び出し、開始時のユーザー [expectedUserId] と一致する場合のみ保存する
  Future<bool> refreshToken(String? expectedUserId) async {
    final refresh = await _withUserMatchLock<String?>(
      expectedUserId: expectedUserId,
      onMismatch: null,
      action: tokenStorage.getRefreshToken,
    );
    if (refresh == null) return false;

    final response = await api.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refresh},
    );

    final access = response.data?['access_token'] as String?;
    if (access == null) return false;

    return await _withUserMatchLock<bool>(
      expectedUserId: expectedUserId,
      onMismatch: false,
      action: () async {
        await tokenStorage.saveTokens(
          accessToken: access,
          refreshToken: refresh,
        );
        return true;
      },
    );
  }

  Future<T> _withUserMatchLock<T>({
    required String? expectedUserId,
    required T onMismatch,
    required Future<T> Function() action,
  }) {
    return _sessionLock.synchronized(() async {
      // 確認後に別アカウントへ切り替わる競合を防ぐため、同一ロック内でユーザーを照合してからストレージ操作を行う
      final currentUserId = await tokenStorage.getUserId();
      if (currentUserId != expectedUserId) return onMismatch;

      return await action();
    });
  }
}
