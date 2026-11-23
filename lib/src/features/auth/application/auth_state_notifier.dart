import 'package:flutter_sample/src/core/utils/jwt_utils.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/auth_session_lock.dart';
import 'package:flutter_sample/src/features/auth/data/custom_auth_invalidation_store.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_notifier.g.dart';

/// ログイン状態を管理するStateNotifier
@Riverpod(keepAlive: true)
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  Future<bool> build() async {
    final tokenStorage = ref.watch(tokenStorageProvider);
    final invalidationStore = ref.watch(customAuthInvalidationStoreProvider);
    final sessionLock = ref.watch(authSessionLockProvider);
    final talker = ref.watch(loggerProvider);

    return await sessionLock.synchronized(() async {
      if (await invalidationStore.isLoginPending()) {
        // ログイン保存およびロールバック消去が途中で失敗した場合、部分保存された
        // トークンが残っている可能性があるため、再消去して未確定ログインを防ぐ
        try {
          await tokenStorage.clear();
          sessionLock.recordSignedOutSession();
          await invalidationStore.clearLoginPending();
        } on Object catch (e, st) {
          // 再消去またはフラグ解除に失敗しても、次回起動時に備えてフラグは維持し未ログインにする
          talker.handle(
            e,
            st,
            'Failed to clear unconfirmed login tokens on startup',
          );
          return false;
        }
      }

      final invalidationEntries = await invalidationStore
          .getInvalidationEntries();
      if (invalidationEntries.isNotEmpty) {
        final token = await tokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          final currentUserId = await tokenStorage.getUserId();
          final currentEmail = JwtUtils.getEmail(token);
          final isInvalidatedAccount = invalidationEntries.any(
            (entry) => CustomAuthInvalidationStore.matchesAccount(
              targetUserId: entry.targetUserId,
              targetEmail: entry.targetEmail,
              candidateUserId: currentUserId,
              candidateEmail: currentEmail,
              defaultWhenUnidentifiable: true,
            ),
          );
          if (!isInvalidatedAccount) {
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
              userId: currentUserId,
              email: currentEmail,
            );
            return true;
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
      if (token != null) {
        sessionLock.recordAuthenticatedSession(
          accessToken: token,
          userId: JwtUtils.getUserId(token),
          email: JwtUtils.getEmail(token),
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
  Future<bool> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    try {
      // 初期化（build）の完了を待機して、初期化結果による状態の上書きを防ぐ
      await future;
      final isLoggedIn = await ref
          .read(authRepositoryProvider)
          .login(email, password);
      if (isLoggedIn) {
        state = const AsyncData(true);
      }
      return isLoggedIn;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// ログアウト状態にする
  Future<void> logout() async {
    try {
      final sessionLock = ref.read(authSessionLockProvider);
      await sessionLock.runSessionTransition(() async {
        await ref.read(tokenStorageProvider).clear();
        sessionLock.recordSignedOutSession();
        if (!sessionLock.isDeletionInProgress) {
          await ref
              .read(customAuthInvalidationStoreProvider)
              .clearInvalidated();
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
