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
      final invalidationState = await invalidationStore.getInvalidationState();
      if (invalidationState.isInvalidated) {
        final token = await tokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          final currentUserId = await tokenStorage.getUserId();
          final currentEmail = JwtUtils.getEmail(token);
          final isDifferentAccount =
              !CustomAuthInvalidationStore.matchesAccount(
                targetUserId: invalidationState.targetUserId,
                targetEmail: invalidationState.targetEmail,
                candidateUserId: currentUserId,
                candidateEmail: currentEmail,
                defaultWhenUnidentifiable: true,
              );
          if (isDifferentAccount) {
            // 別アカウントの新規セッションが既に保存済みなら、そのトークンは維持して
            // 古いアカウントの無効化レコードのみ片付ける
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
            return true;
          }
        }

        // 退会時のトークン消去失敗や削除完了前の終了で残留したセッションを復元せず、再消去を試みる
        try {
          await tokenStorage.clear();
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
      return token != null; // トークンがあればログイン状態
    });
  }

  /// ログイン状態にする
  Future<void> login(String accessToken, String refreshToken) async {
    try {
      final sessionLock = ref.read(authSessionLockProvider);
      final tokenStorage = ref.read(tokenStorageProvider);
      final invalidationStore = ref.read(customAuthInvalidationStoreProvider);

      await sessionLock.runSessionTransition(() async {
        await tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        final savedUserId = await tokenStorage.getUserId();
        final savedEmail = JwtUtils.getEmail(accessToken);
        await invalidationStore.clearIfAllowedForLogin(
          userId: savedUserId,
          email: savedEmail,
          isDeletionInProgress: sessionLock.isDeletionInProgress,
        );
      });
      state = const AsyncData(true);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// メールアドレスとパスワードで認証APIを呼び出してログイン状態にする
  Future<void> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    try {
      // 初期化（build）の完了を待機して、初期化結果による状態の上書きを防ぐ
      await future;
      await ref.read(authRepositoryProvider).login(email, password);
      state = const AsyncData(true);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// ログアウト状態にする
  Future<void> logout() async {
    try {
      await ref.read(authSessionLockProvider).runSessionTransition(() async {
        await ref.read(tokenStorageProvider).clear();
        await ref.read(customAuthInvalidationStoreProvider).clearInvalidated();
      });
      state = const AsyncData(false);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// 認証APIでアカウントを削除し、成功後に未ログイン状態へ移行する
  ///
  /// 削除APIが失敗した場合はログイン状態を維持し、UI側で再試行できるようにします。
  Future<void> deleteAccount() async {
    await future;
    final sessionLock = ref.read(authSessionLockProvider);
    final tokenStorage = ref.read(tokenStorageProvider);
    final invalidationStore = ref.read(customAuthInvalidationStoreProvider);
    final startEpoch = sessionLock.sessionEpoch;

    await ref.read(authRepositoryProvider).deleteAccount();

    final shouldMarkSignedOut = await sessionLock.synchronized(() async {
      if (sessionLock.sessionEpoch == startEpoch) {
        return true;
      }
      final token = await tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        return true;
      }
      return await invalidationStore.isInvalidated();
    });
    if (shouldMarkSignedOut) {
      state = const AsyncData(false);
    }
  }
}
