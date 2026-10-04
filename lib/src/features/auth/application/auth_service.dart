import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

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

/// 現在ログイン中のユーザーIDを提供するプロバイダー（未ログイン時はnull）
@Riverpod(keepAlive: true)
String? currentUserId(Ref ref) {
  final useFirebase = ref.watch(
    envConfigProvider.select((c) => c.useFirebaseAuth),
  );

  return useFirebase
      ? ref.watch(firebaseAuthStateProvider.select((s) => s.value?.uid))
      : null;
}

/// 認証関連の高レベルな操作（ログアウトなど）を提供するサービス
@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  return AuthService(
    talker: ref.watch(loggerProvider),
    useFirebaseAuth: ref.watch(
      envConfigProvider.select((c) => c.useFirebaseAuth),
    ),
    firebaseAuthRepository: ref.watch(firebaseAuthRepositoryProvider),
    authStateNotifier: ref.watch(authStateProvider.notifier),
  );
}

/// [AuthService] の実装クラス
class AuthService {
  /// コンストラクタ
  const AuthService({
    required Talker talker,
    required bool useFirebaseAuth,
    required FirebaseAuthRepository firebaseAuthRepository,
    required AuthStateNotifier authStateNotifier,
  }) : _talker = talker,
       _useFirebaseAuth = useFirebaseAuth,
       _firebaseAuthRepository = firebaseAuthRepository,
       _authStateNotifier = authStateNotifier;

  final Talker _talker;
  final bool _useFirebaseAuth;
  final FirebaseAuthRepository _firebaseAuthRepository;
  final AuthStateNotifier _authStateNotifier;

  /// アカウントの認証プロフィール（表示名、メール、アイコン画像URL）を更新します。
  ///
  /// Firebase Auth を使用している場合、Firebaseのアカウント情報を更新します。
  Future<void> updateAuthProfile({
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {
    _talker.info(
      '[AuthService] updateAuthProfile started '
      '(useFirebase: $_useFirebaseAuth)',
    );

    if (_useFirebaseAuth) {
      await _firebaseAuthRepository.updateAuthProfile(
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
      );
    }

    _talker.info('[AuthService] updateAuthProfile completed');
  }

  /// アプリ全体のログアウト処理を実行します。
  ///
  /// - Firebase Auth または自前認証のセッションを終了
  Future<void> signOut() async {
    _talker.info(
      '[AuthService] signOut started (useFirebase: $_useFirebaseAuth)',
    );

    if (_useFirebaseAuth) {
      await _firebaseAuthRepository.signOut();
    } else {
      await _authStateNotifier.logout();
    }

    _talker.info('[AuthService] signOut completed');
  }
}
