import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/exceptions/reauth_exception.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/core/utils/jwt_utils.dart';
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
      await _sessionLock.runSessionTransition(
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

  /// リフレッシュトークンAPIを呼び出し、開始時と同一セッションである場合のみ保存する
  Future<bool> refreshToken(String? expectedUserId) async {
    final startState = await _sessionLock.synchronized(() async {
      final currentUserId = await tokenStorage.getUserId();
      if (currentUserId != expectedUserId) return null;

      final refresh = await tokenStorage.getRefreshToken();
      if (refresh == null) return null;

      return (refreshToken: refresh, sessionEpoch: _sessionLock.sessionEpoch);
    });
    if (startState == null) return false;

    final response = await api.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': startState.refreshToken},
    );

    final access = response.data?['access_token'] as String?;
    if (access == null) return false;

    return await _sessionLock.synchronized(() async {
      // ID未取得(null)トークン同士の切替や同一ユーザーの再ログインも区別するため、
      // ロック内でセッション世代・ユーザーID・リフレッシュトークンをすべて照合する
      if (_sessionLock.sessionEpoch != startState.sessionEpoch) return false;

      final currentUserId = await tokenStorage.getUserId();
      final currentRefreshToken = await tokenStorage.getRefreshToken();
      if (currentUserId != expectedUserId ||
          currentRefreshToken != startState.refreshToken) {
        return false;
      }

      await tokenStorage.saveTokens(
        accessToken: access,
        refreshToken: startState.refreshToken,
      );
      return true;
    });
  }

  /// 保存済みアクセストークンから現在のメールアドレスを取得する（未取得時は null）
  Future<String?> getCurrentEmail() async {
    final token = await tokenStorage.getAccessToken();
    if (token == null) {
      return null;
    }
    return JwtUtils.getEmail(token);
  }

  /// パスワード再認証APIを呼び出す（カスタム認証用）
  ///
  /// パスワード誤り等による 401 はユーザー操作ミスとして
  /// [ReauthWrongPasswordException] へ変換し、`talker.handle` の対象にはしません。
  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    try {
      await api.post<Map<String, dynamic>>(
        '/auth/reauthenticate',
        data: {'email': email, 'password': password},
      );
    } on DioException catch (e) {
      if (e.error is UnauthenticatedException) {
        talker.warning('Custom auth reauthentication failed: invalid password');
        throw const ReauthWrongPasswordException();
      }
      rethrow;
    } on UnauthenticatedException {
      talker.warning('Custom auth reauthentication failed: invalid password');
      throw const ReauthWrongPasswordException();
    }
  }

  /// アカウント削除APIを呼び出し、成功後にローカルのトークンを破棄する（カスタム認証用）
  ///
  /// サーバー側の削除が成功した後は、端末側のトークン消去に失敗しても
  /// Crashlytics へ記録して処理を続行し、未ログイン遷移およびローカル削除を妨げません。
  Future<void> deleteAccount() async {
    final startState = await _sessionLock.synchronized(() async {
      final token = await tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        return null;
      }
      return (accessToken: token, sessionEpoch: _sessionLock.sessionEpoch);
    });
    if (startState == null) {
      throw const AppException.unauthenticated();
    }

    await api.delete<void>(
      '/auth/account',
      options: Options(
        headers: {'Authorization': 'Bearer ${startState.accessToken}'},
      ),
    );

    try {
      await _sessionLock.runSessionTransitionIfCurrent(
        expectedEpoch: startState.sessionEpoch,
        action: tokenStorage.clear,
      );
    } on Object catch (e, st) {
      // サーバー側のアカウント削除は既に完了しているため、
      // ローカルトークン消去失敗は Crashlytics へ記録しつつサインアウト・ローカル削除を続行する
      talker.handle(
        e,
        st,
        'Failed to clear local tokens after account deletion',
      );
    }
  }
}
