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
  /// 要求開始時（呼び出し元指定時を含む）と応答後のセッション世代・削除世代が
  /// 一致する場合のみトークンを保存して `true` を返します。
  /// 待機中にアカウント削除完了や別セッション遷移が起きた場合は保存せずに応答を破棄し、`false` を返します。
  Future<bool> login(
    String email,
    String password, {
    int? startSessionEpoch,
    int? startDeletionEpoch,
  }) async {
    final startState = (startSessionEpoch != null && startDeletionEpoch != null)
        ? (sessionEpoch: startSessionEpoch, deletionEpoch: startDeletionEpoch)
        : await _sessionLock.synchronized(
            () async => (
              sessionEpoch: startSessionEpoch ?? _sessionLock.sessionEpoch,
              deletionEpoch: startDeletionEpoch ?? _sessionLock.deletionEpoch,
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
      return await tryCommitLoginCredentials(
        tokenStorage: tokenStorage,
        invalidationStore: _invalidationStore,
        sessionLock: _sessionLock,
        talker: talker,
        accessToken: access,
        refreshToken: refresh,
        fallbackEmail: email,
        additionalPrecondition: () =>
            _sessionLock.deletionEpoch == startState.deletionEpoch &&
            _sessionLock.sessionEpoch == startState.sessionEpoch,
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

  static String? _normalizeIdentity(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// セッションロック内で事前条件および退会中の識別可否を確認した上で資格情報を確定する
  ///
  /// [additionalPrecondition] が `false` の場合や、退会処理進行中に削除対象と
  /// 照合不能（[AccountMatch.unknown]）なログインを受け取った場合は、
  /// セッション世代を進めずトークンも保存せずに `false` を返します。
  static Future<bool> tryCommitLoginCredentials({
    required TokenStorage tokenStorage,
    required CustomAuthInvalidationStore invalidationStore,
    required AuthSessionLock sessionLock,
    required Talker talker,
    required String accessToken,
    required String refreshToken,
    String? fallbackEmail,
    bool Function()? additionalPrecondition,
  }) async {
    final candidateUserId = _normalizeIdentity(JwtUtils.getUserId(accessToken));
    final candidateEmail =
        _normalizeIdentity(JwtUtils.getEmail(accessToken)) ??
        _normalizeIdentity(fallbackEmail);
    return await sessionLock.runSessionTransitionIf(
      shouldTransition: () async {
        if (additionalPrecondition != null && !additionalPrecondition()) {
          return false;
        }
        if (await _isBlockedUnidentifiableLogin(
          invalidationStore: invalidationStore,
          sessionLock: sessionLock,
          candidateUserId: candidateUserId,
          candidateEmail: candidateEmail,
        )) {
          return false;
        }
        return true;
      },
      action: () => commitValidatedLoginCredentials(
        tokenStorage: tokenStorage,
        invalidationStore: invalidationStore,
        sessionLock: sessionLock,
        talker: talker,
        accessToken: accessToken,
        refreshToken: refreshToken,
        fallbackEmail: fallbackEmail,
      ),
    );
  }

  static Future<bool> _isBlockedUnidentifiableLogin({
    required CustomAuthInvalidationStore invalidationStore,
    required AuthSessionLock sessionLock,
    required String? candidateUserId,
    required String? candidateEmail,
  }) async {
    if (!sessionLock.isDeletionInProgress) {
      return false;
    }
    final entries = await invalidationStore.getInvalidationEntries();
    return entries.any(
      (entry) =>
          CustomAuthInvalidationStore.compareAccounts(
            targetUserId: entry.targetUserId,
            targetEmail: entry.targetEmail,
            candidateUserId: candidateUserId,
            candidateEmail: candidateEmail,
          ) ==
          AccountMatch.unknown,
    );
  }

  /// 未確定ログイン状態を記録した上で無効化状態の確認・解除とトークン保存を行い、
  /// 失敗時は部分保存された資格情報を消去する
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
    final candidateUserId = _normalizeIdentity(JwtUtils.getUserId(accessToken));
    final candidateEmail =
        _normalizeIdentity(JwtUtils.getEmail(accessToken)) ??
        _normalizeIdentity(fallbackEmail);
    // 無効化行を解除する前に未確定ログイン状態を記録し、記録失敗時は無効化行を残し、
    // 解除失敗時や保存/消去ロールバック失敗時も次回起動時に残留トークンを復元しない
    await invalidationStore.markLoginPending();
    // マーカー記録後に無効化状態の確認・解除を実行する（解除失敗時もマーカーは残す）
    await invalidationStore.clearIfAllowedForLogin(
      userId: candidateUserId,
      email: candidateEmail,
      isDeletionInProgress: sessionLock.isDeletionInProgress,
    );
    try {
      await tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: candidateUserId,
        email: candidateEmail,
      );
      await invalidationStore.clearLogoutPending();
      await invalidationStore.clearLoginPending();
      sessionLock.recordAuthenticatedSession(
        accessToken: accessToken,
        userId: candidateUserId,
        email: candidateEmail,
      );
    } on Object {
      var isCleared = false;
      // 途中まで書き込まれた新しい資格情報が残らないようロールバックを試みる
      try {
        await tokenStorage.clear();
        sessionLock.recordSignedOutSession();
        isCleared = true;
      } on Object catch (clearError, clearSt) {
        talker.handle(
          clearError,
          clearSt,
          'Failed to clear partial login tokens after saveTokens error',
        );
      }
      if (isCleared) {
        try {
          await invalidationStore.clearLogoutPending();
          await invalidationStore.clearLoginPending();
        } on Object catch (pendingError, pendingSt) {
          talker.handle(
            pendingError,
            pendingSt,
            'Failed to clear pending login flag after token rollback',
          );
        }
      }
      rethrow;
    }
  }

  /// ログアウト／ログイン未完了または退会無効化により資格情報の再保存を抑止すべきか判定する
  ///
  /// 退会処理がサーバー応答待ちで進行中（[AuthSessionLock.isDeletionInProgress]）かつ
  /// 有効なアクセストークンが存在する再ログイン・別アカウント切替セッションは引き続き更新を許可します。
  /// 非進行中に退会無効化行が残存している場合も、現在のユーザーID・メールアドレスと照合して
  /// 別アカウントと確定した行は無視し、同一アカウントまたは照合不能な行のみ抑止します。
  Future<bool> _hasPendingSessionReset() async {
    if (await _invalidationStore.isLogoutPending() ||
        await _invalidationStore.isLoginPending()) {
      return true;
    }
    final entries = await _invalidationStore.getInvalidationEntries();
    if (entries.isEmpty) {
      return false;
    }
    final accessToken = await tokenStorage.getAccessToken();
    final hasAccessToken = accessToken != null && accessToken.isNotEmpty;
    if (_sessionLock.isDeletionInProgress) {
      return !hasAccessToken;
    }
    final candidateUserId =
        _normalizeIdentity(
          hasAccessToken ? JwtUtils.getUserId(accessToken) : null,
        ) ??
        _normalizeIdentity(await tokenStorage.getUserId());
    final candidateEmail = await _resolveEmailForToken(accessToken);
    return entries.any(
      (entry) => CustomAuthInvalidationStore.matchesAccount(
        targetUserId: entry.targetUserId,
        targetEmail: entry.targetEmail,
        candidateUserId: candidateUserId,
        candidateEmail: candidateEmail,
        defaultWhenUnidentifiable: true,
      ),
    );
  }

  Future<String?> _resolveEmailForToken(String? accessToken) async {
    final hasToken = accessToken != null && accessToken.isNotEmpty;
    return _normalizeIdentity(
          hasToken ? JwtUtils.getEmail(accessToken) : null,
        ) ??
        _normalizeIdentity(
          hasToken
              ? _sessionLock.trackedEmailForAccessToken(accessToken)
              : null,
        ) ??
        _normalizeIdentity(await tokenStorage.getUserEmail());
  }

  /// リフレッシュトークンAPIを呼び出し、開始時と同一セッションである場合のみ保存する
  Future<bool> refreshToken(String? expectedUserId) async {
    final startState = await _sessionLock.synchronized(() async {
      if (await _hasPendingSessionReset()) return null;

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
      if (await _hasPendingSessionReset()) return false;

      final currentUserId = await tokenStorage.getUserId();
      final currentRefreshToken = await tokenStorage.getRefreshToken();
      if (currentUserId != expectedUserId ||
          currentRefreshToken != startState.refreshToken) {
        return false;
      }

      final trackedEmail = switch (_sessionLock.currentSession) {
        AuthenticatedTrackedAuthSession(:final email) => email,
        _ => null,
      };
      final resolvedUserId =
          _normalizeIdentity(JwtUtils.getUserId(access)) ??
          _normalizeIdentity(expectedUserId);
      final resolvedEmail =
          _normalizeIdentity(JwtUtils.getEmail(access)) ??
          _normalizeIdentity(trackedEmail) ??
          _normalizeIdentity(await tokenStorage.getUserEmail());
      await tokenStorage.saveTokens(
        accessToken: access,
        refreshToken: startState.refreshToken,
        userId: resolvedUserId,
        email: resolvedEmail,
        preserveExistingOnFailure: true,
      );
      _sessionLock.recordAuthenticatedSession(
        accessToken: access,
        userId: resolvedUserId,
        email: resolvedEmail,
      );
      return true;
    });
  }

  /// 保存済みアクセストークン・識別情報から現在のメールアドレスを取得する（未取得時は null）
  Future<String?> getCurrentEmail() async {
    return await _sessionLock.synchronized(() async {
      final token = await tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        return null;
      }
      return await _resolveEmailForToken(token);
    });
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
      final startUserId = _normalizeIdentity(await tokenStorage.getUserId());
      final startEmail =
          _normalizeIdentity(JwtUtils.getEmail(token)) ??
          _normalizeIdentity(_sessionLock.trackedEmailForAccessToken(token)) ??
          _normalizeIdentity(await tokenStorage.getUserEmail());
      // サーバー削除要求前に削除対象アカウント情報つきで無効化状態を永続化し、
      // 保存に失敗した場合は削除要求を送らない
      final invalidationEntryId = await _invalidationStore.markInvalidated(
        targetUserId: startUserId,
        targetEmail: startEmail,
      );
      _sessionLock
        ..recordAuthenticatedSession(
          accessToken: token,
          userId: startUserId,
          email: startEmail,
        )
        ..beginDeletion()
        ..registerActiveDeletion(
          entryId: invalidationEntryId,
          userId: startUserId,
          email: startEmail,
        );
      return (
        accessToken: token,
        sessionEpoch: _sessionLock.sessionEpoch,
        invalidationEntryId: invalidationEntryId,
        userId: startUserId,
        email: startEmail,
      );
    });
    if (startState == null) {
      throw const AppException.unauthenticated();
    }

    var didExplicitlyNotDelete = false;
    try {
      try {
        await api.delete<void>(
          '/auth/account',
          options: Options(
            headers: {'Authorization': 'Bearer ${startState.accessToken}'},
          ),
        );
      } on Object catch (e) {
        didExplicitlyNotDelete = _isExplicitNonDeletionFailure(e);
        rethrow;
      }

      var shouldTerminateSession = false;
      try {
        await _sessionLock.runSessionTransitionIf(
          shouldTransition: () async {
            _sessionLock.markDeletionCompleted();
            final outcome = await _resolveDeletionSessionOutcome(startState);
            shouldTerminateSession = outcome.shouldTerminateSession;
            if (!outcome.shouldClearTokens &&
                outcome.shouldClearInvalidationFlag) {
              // 別アカウント切替やサインアウト済みと確定できた場合のみ、
              // この退会処理が所有していたレコードを後片付けする（照合不能時は保持）
              await _clearInvalidationFlagBestEffort(startState);
            }
            return outcome.shouldClearTokens;
          },
          action: () async {
            await tokenStorage.clear();
            _sessionLock.recordSignedOutSession();
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
      var hasFinishedLockCleanup = false;
      if (didExplicitlyNotDelete) {
        await _sessionLock.synchronized(() async {
          await _clearInvalidationFlagBestEffort(
            startState,
            onlyOwnEntry: true,
          );
          _sessionLock
            ..unregisterActiveDeletion(startState.invalidationEntryId)
            ..endDeletion();
          hasFinishedLockCleanup = true;
        });
      }
      if (!hasFinishedLockCleanup) {
        _sessionLock
          ..unregisterActiveDeletion(startState.invalidationEntryId)
          ..endDeletion();
      }
    }
  }

  Future<
    ({
      bool shouldClearTokens,
      bool shouldTerminateSession,
      bool shouldClearInvalidationFlag,
    })
  >
  _resolveDeletionSessionOutcome(_DeletionStartState startState) async {
    if (_sessionLock.sessionEpoch == startState.sessionEpoch) {
      return (
        shouldClearTokens: true,
        shouldTerminateSession: true,
        shouldClearInvalidationFlag: true,
      );
    }
    try {
      final currentToken = await tokenStorage.getAccessToken();
      if (currentToken == null || currentToken.isEmpty) {
        final currentRefreshToken = await tokenStorage.getRefreshToken();
        final currentUserId = await tokenStorage.getUserId();
        final currentUserEmail = await tokenStorage.getUserEmail();
        final hasRemainingCredentials =
            currentToken != null ||
            (currentRefreshToken != null && currentRefreshToken.isNotEmpty) ||
            (currentUserId != null && currentUserId.isNotEmpty) ||
            (currentUserEmail != null && currentUserEmail.isNotEmpty);
        if (!hasRemainingCredentials) {
          // 全キー（accessToken / refreshToken / customUserId / customUserEmail）の消去完了を確認できた場合のみ、
          // 余計なトークン消去や世代更新をせず終了扱いとする
          return (
            shouldClearTokens: false,
            shouldTerminateSession: true,
            shouldClearInvalidationFlag: true,
          );
        }
        // 一部キーのみ残留している消去未完了状態では TokenStorage.clear() を再試行し、
        // 再試行にも失敗した場合は無効化行を保持したまま未ログインへの遷移を続ける
        return (
          shouldClearTokens: true,
          shouldTerminateSession: true,
          shouldClearInvalidationFlag: true,
        );
      }
      final currentUserId = _normalizeIdentity(await tokenStorage.getUserId());
      final currentEmail =
          _normalizeIdentity(JwtUtils.getEmail(currentToken)) ??
          _normalizeIdentity(
            _sessionLock.trackedEmailForAccessToken(currentToken),
          ) ??
          _normalizeIdentity(await tokenStorage.getUserEmail());
      return _matchTargetAccountOutcome(
        startState: startState,
        candidateUserId: currentUserId,
        candidateEmail: currentEmail,
      );
    } on Object catch (e, st) {
      // 読み取り失敗時は世代変更前の別アカウント切替と同一アカウント再ログインを区別するため、
      // ロック内に保持している最新セッション識別情報へフォールバックする
      talker.handle(
        e,
        st,
        'Failed to read current token while resolving account deletion outcome',
      );
      return _resolveDeletionOutcomeFromTrackedSession(startState);
    }
  }

  ({
    bool shouldClearTokens,
    bool shouldTerminateSession,
    bool shouldClearInvalidationFlag,
  })
  _resolveDeletionOutcomeFromTrackedSession(_DeletionStartState startState) {
    return switch (_sessionLock.currentSession) {
      SignedOutTrackedAuthSession() => (
        // 読み取り失敗時は全キー消去を確認できないため TokenStorage.clear() を再試行し、
        // 全キー消去に成功した場合のみ無効化行を解除する（失敗時は保持）
        shouldClearTokens: true,
        shouldTerminateSession: true,
        shouldClearInvalidationFlag: true,
      ),
      AuthenticatedTrackedAuthSession(:final userId, :final email) =>
        _matchTargetAccountOutcome(
          startState: startState,
          candidateUserId: userId,
          candidateEmail: email,
        ),
    };
  }

  ({
    bool shouldClearTokens,
    bool shouldTerminateSession,
    bool shouldClearInvalidationFlag,
  })
  _matchTargetAccountOutcome({
    required _DeletionStartState startState,
    required String? candidateUserId,
    required String? candidateEmail,
  }) {
    return switch (CustomAuthInvalidationStore.compareAccounts(
      targetUserId: startState.userId,
      targetEmail: startState.email,
      candidateUserId: candidateUserId,
      candidateEmail: candidateEmail,
    )) {
      AccountMatch.same => (
        shouldClearTokens: true,
        shouldTerminateSession: true,
        shouldClearInvalidationFlag: true,
      ),
      AccountMatch.different => (
        shouldClearTokens: false,
        shouldTerminateSession: false,
        shouldClearInvalidationFlag: true,
      ),
      AccountMatch.unknown => (
        shouldClearTokens: false,
        shouldTerminateSession: false,
        shouldClearInvalidationFlag: false,
      ),
    };
  }

  static bool _isExplicitNonDeletionFailure(Object error) {
    final actual = error is DioException ? (error.error ?? error) : error;
    if (actual is ReauthException) {
      return true;
    }
    if (actual is AppException) {
      return switch (actual) {
        UnauthenticatedException() || UnauthorizedException() => true,
        BadRequestException(:final statusCode) => statusCode != 408,
        NetworkException() ||
        ServerException() ||
        TimeoutException() ||
        DataParseException() ||
        DatabaseException() ||
        CancelException() ||
        UnknownException() => false,
      };
    }
    if (error is DioException && error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      return statusCode != null &&
          statusCode >= 400 &&
          statusCode < 500 &&
          statusCode != 408;
    }
    return false;
  }

  Future<void> _clearInvalidationFlagBestEffort(
    _DeletionStartState startState, {
    bool onlyOwnEntry = false,
  }) async {
    try {
      final shouldDeleteOnlyOwnEntry =
          onlyOwnEntry ||
          _sessionLock.hasOtherActiveDeletion(
            entryId: startState.invalidationEntryId,
            userId: startState.userId,
            email: startState.email,
          );
      await _invalidationStore.clearInvalidatedIfMatches(
        entryId: shouldDeleteOnlyOwnEntry
            ? startState.invalidationEntryId
            : null,
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

typedef _DeletionStartState = ({
  String accessToken,
  int sessionEpoch,
  int invalidationEntryId,
  String? userId,
  String? email,
});
