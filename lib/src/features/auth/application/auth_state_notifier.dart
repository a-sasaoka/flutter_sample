import 'package:flutter_sample/src/core/utils/jwt_utils.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/auth_session_lock.dart';
import 'package:flutter_sample/src/features/auth/data/custom_auth_invalidation_store.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'auth_state_notifier.g.dart';

/// ログイン状態を管理するStateNotifier
@Riverpod(keepAlive: true)
class AuthStateNotifier extends _$AuthStateNotifier {
  static String? _normalizeIdentity(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<bool> _clearPendingTokensOnStartup({
    required Future<bool> Function() isPending,
    required Future<void> Function() clearPending,
    required TokenStorage tokenStorage,
    required AuthSessionLock sessionLock,
    required Talker talker,
    required String failureLogMessage,
  }) async {
    if (!await isPending()) {
      return true;
    }
    try {
      await tokenStorage.clear();
      sessionLock.recordSignedOutSession();
      await clearPending();
      return true;
    } on Object catch (e, st) {
      sessionLock.recordSignedOutSession();
      // 再消去またはフラグ解除に失敗しても、次回起動時に備えてフラグは維持し未ログインにする
      talker.handle(e, st, failureLogMessage);
      return false;
    }
  }

  static bool _matchesJwtDirectly(
    CustomAuthInvalidationEntry entry, {
    required String? jwtUserId,
    required String? jwtEmail,
  }) {
    if (jwtUserId != null && entry.targetUserId == jwtUserId) {
      return true;
    }
    if (entry.targetUserId == null && jwtEmail != null) {
      return CustomAuthInvalidationStore.compareAccounts(
            targetUserId: null,
            targetEmail: entry.targetEmail,
            candidateUserId: null,
            candidateEmail: jwtEmail,
          ) ==
          AccountMatch.same;
    }
    return false;
  }

  Future<String?> _readIdentityBestEffort({
    required Future<String?> Function() readIdentity,
    required Talker talker,
    required String failureLogMessage,
  }) async {
    try {
      return _normalizeIdentity(await readIdentity());
    } on Object catch (e, st) {
      talker.handle(e, st, failureLogMessage);
      return null;
    }
  }

  Future<String?> _readUserIdBestEffort(
    TokenStorage tokenStorage,
    Talker talker,
  ) => _readIdentityBestEffort(
    readIdentity: tokenStorage.getUserId,
    talker: talker,
    failureLogMessage:
        'Failed to read user id while restoring session on startup',
  );

  Future<String?> _readUserEmailBestEffort(
    TokenStorage tokenStorage,
    Talker talker,
  ) => _readIdentityBestEffort(
    readIdentity: tokenStorage.getUserEmail,
    talker: talker,
    failureLogMessage:
        'Failed to read user email while restoring session on startup',
  );

  Future<
    ({bool shouldClear, bool isAuthenticated, String? userId, String? email})
  >
  _resolveStartupInvalidationOutcome({
    required List<CustomAuthInvalidationEntry> invalidationEntries,
    required String token,
    required TokenStorage tokenStorage,
    required Talker talker,
  }) async {
    final jwtUserId = _normalizeIdentity(JwtUtils.getUserId(token));
    final jwtEmail = _normalizeIdentity(JwtUtils.getEmail(token));

    // JWTクレームだけで削除対象と一致した場合は、保存済み識別情報の読み取り失敗で
    // 退会済みセッション消去を妨げないようストレージ識別情報へアクセスせず消去へ進む
    if (invalidationEntries.any(
      (entry) =>
          _matchesJwtDirectly(entry, jwtUserId: jwtUserId, jwtEmail: jwtEmail),
    )) {
      return (
        shouldClear: true,
        isAuthenticated: false,
        userId: jwtUserId,
        email: jwtEmail,
      );
    }

    // 無効化行がすべてメールのみで JWT のメールから照合できる場合は、
    // getUserId() 読み取り前にメールで判定し、別メールなら ID 取得失敗時も復元を続ける
    final canMatchByJwtEmailOnly =
        jwtUserId == null &&
        jwtEmail != null &&
        invalidationEntries.every((entry) => entry.targetUserId == null);
    if (canMatchByJwtEmailOnly) {
      final isInvalidatedAccount = invalidationEntries.any(
        (entry) => CustomAuthInvalidationStore.matchesAccount(
          targetUserId: null,
          targetEmail: entry.targetEmail,
          candidateUserId: null,
          candidateEmail: jwtEmail,
          defaultWhenUnidentifiable: true,
        ),
      );
      if (isInvalidatedAccount) {
        return (
          shouldClear: true,
          isAuthenticated: false,
          userId: null,
          email: jwtEmail,
        );
      }
      final restoredUserId = await _readUserIdBestEffort(tokenStorage, talker);
      return (
        shouldClear: false,
        isAuthenticated: true,
        userId: restoredUserId,
        email: jwtEmail,
      );
    }

    late final String? currentUserId;
    if (jwtUserId != null) {
      currentUserId = jwtUserId;
    } else {
      try {
        currentUserId = _normalizeIdentity(await tokenStorage.getUserId());
      } on Object catch (e, st) {
        talker.handle(
          e,
          st,
          'Failed to read user id during startup invalidation check',
        );
        return (
          shouldClear: false,
          isAuthenticated: false,
          userId: null,
          email: null,
        );
      }
    }

    if (invalidationEntries.any(
      (entry) =>
          CustomAuthInvalidationStore.compareAccounts(
            targetUserId: entry.targetUserId,
            targetEmail: entry.targetEmail,
            candidateUserId: currentUserId,
            candidateEmail: jwtEmail,
          ) ==
          AccountMatch.same,
    )) {
      return (
        shouldClear: true,
        isAuthenticated: false,
        userId: currentUserId,
        email: jwtEmail,
      );
    }

    final needsEmailLookup =
        jwtEmail == null &&
        invalidationEntries.any(
          (entry) =>
              !(entry.targetUserId != null && currentUserId != null) &&
              _normalizeIdentity(entry.targetEmail) != null,
        );
    late final String? currentEmail;
    if (needsEmailLookup) {
      try {
        currentEmail = _normalizeIdentity(await tokenStorage.getUserEmail());
      } on Object catch (e, st) {
        talker.handle(
          e,
          st,
          'Failed to read user email during startup invalidation check',
        );
        return (
          shouldClear: false,
          isAuthenticated: false,
          userId: currentUserId,
          email: null,
        );
      }
    } else {
      currentEmail = jwtEmail;
    }

    final isInvalidatedAccount = invalidationEntries.any(
      (entry) => CustomAuthInvalidationStore.matchesAccount(
        targetUserId: entry.targetUserId,
        targetEmail: entry.targetEmail,
        candidateUserId: currentUserId,
        candidateEmail: currentEmail,
        defaultWhenUnidentifiable: true,
      ),
    );
    if (isInvalidatedAccount) {
      return (
        shouldClear: true,
        isAuthenticated: false,
        userId: currentUserId,
        email: currentEmail,
      );
    }

    return (
      shouldClear: false,
      isAuthenticated: true,
      userId: currentUserId,
      email:
          currentEmail ?? await _readUserEmailBestEffort(tokenStorage, talker),
    );
  }

  @override
  Future<bool> build() async {
    final tokenStorage = ref.watch(tokenStorageProvider);
    final invalidationStore = ref.watch(customAuthInvalidationStoreProvider);
    final sessionLock = ref.watch(authSessionLockProvider);
    final talker = ref.watch(loggerProvider);

    return await sessionLock.synchronized(() async {
      // ログイン保存・ロールバック消去または通常ログアウトの消去が途中で失敗した場合は、
      // 一部キー（例: customUserEmail）が残留している可能性があるため起動時に再消去する
      if (!await _clearPendingTokensOnStartup(
        isPending: invalidationStore.isLoginPending,
        clearPending: invalidationStore.clearLoginPending,
        tokenStorage: tokenStorage,
        sessionLock: sessionLock,
        talker: talker,
        failureLogMessage:
            'Failed to clear unconfirmed login tokens on startup',
      )) {
        return false;
      }
      if (!await _clearPendingTokensOnStartup(
        isPending: invalidationStore.isLogoutPending,
        clearPending: invalidationStore.clearLogoutPending,
        tokenStorage: tokenStorage,
        sessionLock: sessionLock,
        talker: talker,
        failureLogMessage: 'Failed to clear pending logout tokens on startup',
      )) {
        return false;
      }

      final invalidationEntries = await invalidationStore
          .getInvalidationEntries();
      if (invalidationEntries.isNotEmpty) {
        final token = await tokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          final outcome = await _resolveStartupInvalidationOutcome(
            invalidationEntries: invalidationEntries,
            token: token,
            tokenStorage: tokenStorage,
            talker: talker,
          );
          if (outcome.isAuthenticated) {
            // どの無効化レコードにも該当しない別アカウントの新規セッションなら、
            // そのトークンは維持して古い無効化レコードのみ片付ける
            try {
              await invalidationStore.clearInvalidated();
            } on Object catch (e, st) {
              talker.handle(
                e,
                st,
                'Failed to clear obsolete custom auth invalidation flag '
                'on startup',
              );
            }
            sessionLock.recordAuthenticatedSession(
              accessToken: token,
              userId: outcome.userId,
              email: outcome.email,
            );
            return true;
          }
          if (!outcome.shouldClear) {
            // 識別情報の読み取り失敗等で照合できない場合は無効化行を保持したまま未ログインにする
            sessionLock.recordSignedOutSession();
            return false;
          }
        }

        // 退会時のトークン消去失敗や削除完了前の終了で残留したセッションを復元せず、再消去を試みる
        try {
          await tokenStorage.clear();
          sessionLock.recordSignedOutSession();
          await invalidationStore.clearInvalidated();
        } on Object catch (e, st) {
          // 再消去に失敗しても次回起動時にログイン復元されないよう無効化フラグは維持する
          talker.handle(
            e,
            st,
            'Failed to clear invalidated custom auth tokens on startup',
          );
        }
        return false;
      }

      final token = await tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final currentUserId = await _readUserIdBestEffort(tokenStorage, talker);
        final currentEmail = await _readUserEmailBestEffort(
          tokenStorage,
          talker,
        );
        sessionLock.recordAuthenticatedSession(
          accessToken: token,
          userId: currentUserId,
          email: currentEmail,
        );
        return true; // トークンがあればログイン状態
      }
      sessionLock.recordSignedOutSession();
      return false;
    });
  }

  /// ログイン状態にする
  ///
  /// 退会処理進行中に削除対象と識別できない（照合不能な）再ログインだった場合は
  /// 資格情報を確定せずに `false` を返し、状態も変更しません。
  Future<bool> login(String accessToken, String refreshToken) async {
    try {
      final sessionLock = ref.read(authSessionLockProvider);
      final tokenStorage = ref.read(tokenStorageProvider);
      final invalidationStore = ref.read(customAuthInvalidationStoreProvider);
      final talker = ref.read(loggerProvider);

      final isCommitted = await AuthRepository.tryCommitLoginCredentials(
        tokenStorage: tokenStorage,
        invalidationStore: invalidationStore,
        sessionLock: sessionLock,
        talker: talker,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      if (isCommitted) {
        state = const AsyncData(true);
      }
      return isCommitted;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// メールアドレスとパスワードで認証APIを呼び出してログイン状態にする
  ///
  /// 古いログイン応答が削除完了後などに届いて破棄された場合は `false` を返し、
  /// 現在の認証状態（未ログインまたは他セッション）を上書きしません。
  /// 古い要求が例外で失敗した場合も、要求開始時のセッション世代・削除世代と
  /// 一致しない限り `state` を `AsyncError` へ変更せず、元の例外のみを再スローします。
  Future<bool> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    final sessionLock = ref.read(authSessionLockProvider);
    final startSessionEpoch = sessionLock.sessionEpoch;
    final startDeletionEpoch = sessionLock.deletionEpoch;
    try {
      // 初期化（build）が進行中なら完了を待機し、エラー後（AsyncError）からはそのままログインを続行する
      if (state.isLoading) {
        await future;
      }
      final isLoggedIn = await ref
          .read(authRepositoryProvider)
          .login(
            email,
            password,
            startSessionEpoch: startSessionEpoch,
            startDeletionEpoch: startDeletionEpoch,
          );
      if (isLoggedIn) {
        state = const AsyncData(true);
      }
      return isLoggedIn;
    } catch (e, st) {
      if (sessionLock.sessionEpoch == startSessionEpoch &&
          sessionLock.deletionEpoch == startDeletionEpoch) {
        state = AsyncError(e, st);
      }
      rethrow;
    }
  }

  /// ログアウト状態にする
  Future<void> logout() async {
    try {
      final sessionLock = ref.read(authSessionLockProvider);
      final tokenStorage = ref.read(tokenStorageProvider);
      final invalidationStore = ref.read(customAuthInvalidationStoreProvider);
      final talker = ref.read(loggerProvider);
      Future<bool> runBestEffort(
        Future<void> Function() action,
        String failureLogMessage,
      ) async {
        try {
          await action();
          return true;
        } on Object catch (e, st) {
          talker.handle(e, st, failureLogMessage);
          return false;
        }
      }

      await sessionLock.runSessionTransition(() async {
        // 保留フラグ永続化に失敗してもログアウトを止めず、トークン消去を試行する
        final hasPendingLogoutFlag = await runBestEffort(
          invalidationStore.markLogoutPending,
          'Failed to record pending logout flag on logout',
        );
        sessionLock.recordSignedOutSession();
        await tokenStorage.clear();
        if (hasPendingLogoutFlag) {
          // 全4キーの消去自体は完了しているため、記録解除の失敗だけでログアウトを失敗扱いにしない
          await runBestEffort(
            invalidationStore.clearLogoutPending,
            'Failed to clear pending logout flag on logout',
          );
        }
        if (!sessionLock.isDeletionInProgress) {
          // トークン消去は既に完了しているため、無効化フラグ解除の失敗だけで
          // ログアウト全体を失敗扱いにしない
          await runBestEffort(
            invalidationStore.clearInvalidated,
            'Failed to clear custom auth invalidation flag on logout',
          );
        }
      });
      state = const AsyncData(false);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// 認証APIでアカウントを削除し、対象セッションを終了すべき場合は未ログイン状態へ移行する
  ///
  /// 対象セッションを終了した場合は `true`、処理中に別アカウントへ切り替わり
  /// そのセッションを保持した場合は `false` を返します。削除APIが失敗した場合は
  /// 例外を再スローしてログイン状態を維持し、UI側で再試行できるようにします。
  Future<bool> deleteAccount() async {
    await future;
    final shouldTerminateSession = await ref
        .read(authRepositoryProvider)
        .deleteAccount();
    if (shouldTerminateSession) {
      state = const AsyncData(false);
    }
    return shouldTerminateSession;
  }
}
