import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

/// 認証方式（Firebase / 自前認証）に依存しないログイン状態を提供するプロバイダー
@Riverpod(keepAlive: true)
bool isAuthenticated(Ref ref) {
  final useFirebase = ref.watch(
    envConfigProvider.select((c) => c.useFirebaseAuth),
  );

  return useFirebase
      ? ref.watch(firebaseAuthStateProvider.select((s) => s.value != null))
      : ref.watch(authStateProvider.select((s) => s.value == true));
}

/// 認証関連の高レベルな操作（ログアウト、アプリロック連携など）を提供するサービス
@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  return AuthService(ref);
}

/// [AuthService] の実装クラス
class AuthService {
  /// コンストラクタ
  const AuthService(this._ref);

  final Ref _ref;

  /// アプリ全体のログアウト処理を実行します。
  ///
  /// - Firebase Auth または自前認証のセッションを終了
  /// - アプリロック（パスコード・生体認証設定）をクリア
  Future<void> signOut() async {
    final talker = _ref.read(loggerProvider);
    final useFirebase = _ref.read(envConfigProvider).useFirebaseAuth;

    talker.info('[AuthService] signOut started (useFirebase: $useFirebase)');

    if (useFirebase) {
      await _ref.read(firebaseAuthRepositoryProvider).signOut();
    } else {
      await _ref.read(authStateProvider.notifier).logout();
    }

    try {
      await _ref.read(appLockServiceProvider.notifier).clearAppLock();
      talker.debug('[AuthService] clearAppLock succeeded');
    } on Object catch (e, st) {
      talker.handle(e, st, '[AuthService] Failed to clear app lock');
    }

    talker.info('[AuthService] signOut completed');
  }
}
