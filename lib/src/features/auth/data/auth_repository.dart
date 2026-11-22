import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/exceptions/reauth_exception.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/core/utils/jwt_utils.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/data/auth_session_lock.dart';
import 'package:flutter_sample/src/features/auth/data/custom_auth_invalidation_store.dart';
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
    invalidationStore: ref.watch(customAuthInvalidationStoreProvider),
  );
}

/// 認証リポジトリの実装クラス
class AuthRepository {
  /// コンストラクタ
  AuthRepository({
    required this.api,
    required this.tokenStorage,
    required this.talker,
    required CustomAuthInvalidationStore invalidationStore,
    AuthSessionLock? sessionLock,
  }) : _invalidationStore = invalidationStore,
       _sessionLock = sessionLock ?? AuthSessionLock();

  /// APIクライアント
  final ApiClient api;

  /// トークンストレージ
  final TokenStorage tokenStorage;

  /// ロガー
  final Talker talker;

  final CustomAuthInvalidationStore _invalidationStore;
  final AuthSessionLock _sessionLock;

  /// ログインAPIを呼び出し、古い応答を破棄した上でトークンを保存する
  ///
  /// 要求開始時と応答後のセッション世代・削除世代が一致する場合のみトークンを保存して `true` を返します。
  /// 待機中にアカウント削除完了や別セッション遷移が起きた場合は保存せずに応答を破棄し、`false` を返します。
  Future<bool> login(String email, String password) async {
    final startState = await _sessionLock.synchronized(
      () async => (
        sessionEpoch: _sessionLock.sessionEpoch,
        deletionEpoch: _sessionLock.deletionEpoch,
      ),
    );

    final response = await api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    if (response.data case {
      'access_token': final String access,
      'refresh_token': final String refresh,
    }) {
      return await _sessionLock.runSessionTransitionIf(
        shouldTransition: () async =>
            _sessionLock.deletionEpoch == startState.deletionEpoch &&
            _sessionLock.sessionEpoch == startState.sessionEpoch,
        action: () => commitValidatedLoginCredentials(
          tokenStorage: tokenStorage,
          invalidationStore: _invalidationStore,
          sessionLock: _sessionLock,
          talker: talker,
          accessToken: access,
          refreshToken: refresh,
          fallbackEmail: email,
        ),
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

  /// 無効化状態の解除確認後にトークンを保存し、失敗時は部分保存された資格情報を消去する
  ///
  /// `AuthStateNotifier.login` と [login] の双方から同一の確定・ロールバック経路を
  /// 利用することで、失敗時に保存済みトークンが残らない挙動を揃えます。
  static Future<void> commitValidatedLoginCredentials({
    required TokenStorage tokenStorage,
    required CustomAuthInvalidationStore invalidationStore,
    required AuthSessionLock sessionLock,
    required Talker talker,
    required String accessToken,
    required String refreshToken,
    String? fallbackEmail,
  }) async {
    final candidateUserId = JwtUtils.getUserId(accessToken);
    final candidateEmail = JwtUtils.getEmail(accessToken) ?? fallbackEmail;
    // DB 確認・解除が失敗した場合に新しい資格情報を残さないため、保存前に実行する
    await invalidationStore.clearIfAllowedForLogin(
      userId: candidateUserId,
      email: candidateEmail,
      isDeletionInProgress: sessionLock.isDeletionInProgress,
    );
    try {
      await tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on Object {
      // 途中まで書き込まれた新しい資格情報が残らないようロールバックを試みる
      try {
        await tokenStorage.clear();
      } on Object catch (clearError, clearSt) {
        talker.handle(
          clearError,
          clearSt,
          'Failed to clear partial login tokens after saveTokens error',
        );
      }
      rethrow;
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

  /// アカウント削除APIを呼び出し、成功後に削除対象セッションを終了すべきかを返す（カスタム認証用）
  ///
  /// サーバーへ削除要求を送る前に削除対象アカウント識別子付きでセッション無効化状態を
  /// ディスクへ永続化し、保存に失敗した場合は削除要求を送信しません。API待機中に
  /// 同じアカウントで再ログインが行われた場合も削除完了後・再起動後の復元を防ぎ、
  /// 削除対象セッションを終了する意図で `true` を返します。別アカウントへの切り替え時のみ
  /// 新セッションを保護し、呼出元でもセッション終了を行わないよう `false` を返します。
  /// サーバー側の削除が成功した後は、端末側のトークン消去や無効化解除に失敗しても
  /// Crashlytics へ記録して処理を続行し、未ログイン遷移およびローカル削除を妨げません。
  Future<bool> deleteAccount() async {
    final startState = await _sessionLock.synchronized(() async {
      final token = await tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        return null;
      }
      final startUserId = await tokenStorage.getUserId();
      final startEmail = JwtUtils.getEmail(token);
      // サーバー削除要求前に削除対象アカウント情報つきで無効化状態を永続化し、
      // 保存に失敗した場合は削除要求を送らない
      await _invalidationStore.markInvalidated(
        targetUserId: startUserId,
        targetEmail: startEmail,
      );
      _sessionLock.beginDeletion();
      return (
        accessToken: token,
        sessionEpoch: _sessionLock.sessionEpoch,
        userId: startUserId,
        email: startEmail,
      );
    });
    if (startState == null) {
      throw const AppException.unauthenticated();
    }

    try {
      await api.delete<void>(
        '/auth/account',
        options: Options(
          headers: {'Authorization': 'Bearer ${startState.accessToken}'},
        ),
      );

      var shouldTerminateSession = false;
      try {
        await _sessionLock.runSessionTransitionIf(
          shouldTransition: () async {
            _sessionLock.markDeletionCompleted();
            final outcome = await _resolveDeletionSessionOutcome(startState);
            shouldTerminateSession = outcome.shouldTerminateSession;
            if (!outcome.shouldClearTokens) {
              // 別アカウントへ切り替わった場合も、この退会処理が所有していたレコードのみ後片付けする
              await _clearInvalidationFlagBestEffort(startState);
            }
            return outcome.shouldClearTokens;
          },
          action: () async {
            await tokenStorage.clear();
            await _clearInvalidationFlagBestEffort(startState);
          },
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
      return shouldTerminateSession;
    } finally {
      _sessionLock.endDeletion();
    }
  }

  Future<({bool shouldClearTokens, bool shouldTerminateSession})>
  _resolveDeletionSessionOutcome(
    ({String accessToken, int sessionEpoch, String? userId, String? email})
    startState,
  ) async {
    if (_sessionLock.sessionEpoch == startState.sessionEpoch) {
      return (shouldClearTokens: true, shouldTerminateSession: true);
    }
    final currentToken = await tokenStorage.getAccessToken();
    if (currentToken == null || currentToken.isEmpty) {
      // 既に別操作でサインアウト済みの場合は余計なトークン消去や世代更新をせず終了扱いとする
      return (shouldClearTokens: false, shouldTerminateSession: true);
    }
    final currentUserId = await tokenStorage.getUserId();
    final currentEmail = JwtUtils.getEmail(currentToken);
    final isTargetAccount = CustomAuthInvalidationStore.matchesAccount(
      targetUserId: startState.userId,
      targetEmail: startState.email,
      candidateUserId: currentUserId,
      candidateEmail: currentEmail,
      defaultWhenUnidentifiable: false,
    );
    return (
      shouldClearTokens: isTargetAccount,
      shouldTerminateSession: isTargetAccount,
    );
  }

  Future<void> _clearInvalidationFlagBestEffort(
    ({String accessToken, int sessionEpoch, String? userId, String? email})
    startState,
  ) async {
    try {
      await _invalidationStore.clearInvalidatedIfMatches(
        targetUserId: startState.userId,
        targetEmail: startState.email,
      );
    } on Object catch (e, st) {
      talker.handle(
        e,
        st,
        'Failed to clear invalidated custom auth session flag',
      );
    }
  }
}
