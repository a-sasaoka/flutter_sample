import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/exceptions/reauth_exception.dart';
import 'package:flutter_sample/src/core/services/lock_suppression_handler.dart';
import 'package:flutter_sample/src/core/storage/cache_manager.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/account_deletion_notice_notifier.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:flutter_sample/src/features/auth/domain/account_deletion_precheck.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/profile/data/profile_repository.dart';
import 'package:flutter_sample/src/features/profile/data/storage_service.dart';
import 'package:flutter_sample/src/features/qr_scanner/data/qr_scan_histories_dao.dart';
import 'package:flutter_sample/src/features/user/data/user_repository.dart';
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

/// 独自認証モードでのログイン中ユーザーIDを提供するプロバイダー（未ログイン時はnull）
@Riverpod(keepAlive: true)
Future<String?> customUserId(Ref ref) async {
  final isAuthed = await ref.watch(authStateProvider.future);
  if (!isAuthed) {
    return null;
  }
  return await ref.watch(tokenStorageProvider).getUserId();
}

/// 現在ログイン中のユーザーIDを提供するプロバイダー（未ログイン時はnull）
@Riverpod(keepAlive: true)
String? currentUserId(Ref ref) {
  final useFirebase = ref.watch(
    envConfigProvider.select((c) => c.useFirebaseAuth),
  );

  return useFirebase
      ? ref.watch(firebaseAuthStateProvider.select((s) => s.value?.uid))
      : ref.watch(customUserIdProvider.select((s) => s.value));
}

/// 認証関連の高レベルな操作（ログアウト・再認証・アカウント削除など）を提供するサービス
@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  return AuthService(
    talker: ref.watch(loggerProvider),
    useFirebaseAuth: ref.watch(
      envConfigProvider.select((c) => c.useFirebaseAuth),
    ),
    firebaseAuthRepository: ref.watch(firebaseAuthRepositoryProvider),
    authRepository: ref.watch(authRepositoryProvider),
    authStateNotifier: ref.watch(authStateProvider.notifier),
    tokenStorage: ref.watch(tokenStorageProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
    storageService: ref.watch(storageServiceProvider),
    memoRepository: ref.watch(memoRepositoryProvider),
    qrScanHistoriesDao: ref.watch(qrScanHistoriesDaoProvider),
    cacheManager: ref.watch(cacheManagerProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
    accountDeletionNoticeNotifier: ref.watch(
      accountDeletionNoticeProvider.notifier,
    ),
    clock: ref.watch(clockProvider),
    runWithLockSuppression: ref.watch(lockSuppressionRunnerProvider),
  );
}

/// [AuthService] の実装クラス
class AuthService {
  /// コンストラクタ
  const AuthService({
    required Talker talker,
    required bool useFirebaseAuth,
    required FirebaseAuthRepository firebaseAuthRepository,
    required AuthRepository authRepository,
    required AuthStateNotifier authStateNotifier,
    required TokenStorage tokenStorage,
    required ProfileRepository profileRepository,
    required StorageService storageService,
    required MemoRepository memoRepository,
    required QrScanHistoriesDao qrScanHistoriesDao,
    required CacheManager cacheManager,
    required AnalyticsService analyticsService,
    required AccountDeletionNoticeNotifier accountDeletionNoticeNotifier,
    required DateTime Function() clock,
    required LockSuppressionRunner runWithLockSuppression,
  }) : _talker = talker,
       _useFirebaseAuth = useFirebaseAuth,
       _firebaseAuthRepository = firebaseAuthRepository,
       _authRepository = authRepository,
       _authStateNotifier = authStateNotifier,
       _tokenStorage = tokenStorage,
       _profileRepository = profileRepository,
       _storageService = storageService,
       _memoRepository = memoRepository,
       _qrScanHistoriesDao = qrScanHistoriesDao,
       _cacheManager = cacheManager,
       _analyticsService = analyticsService,
       _accountDeletionNoticeNotifier = accountDeletionNoticeNotifier,
       _clock = clock,
       _runWithLockSuppression = runWithLockSuppression;

  final Talker _talker;
  final bool _useFirebaseAuth;
  final FirebaseAuthRepository _firebaseAuthRepository;
  final AuthRepository _authRepository;
  final AuthStateNotifier _authStateNotifier;
  final TokenStorage _tokenStorage;
  final ProfileRepository _profileRepository;
  final StorageService _storageService;
  final MemoRepository _memoRepository;
  final QrScanHistoriesDao _qrScanHistoriesDao;
  final CacheManager _cacheManager;
  final AnalyticsService _analyticsService;
  final AccountDeletionNoticeNotifier _accountDeletionNoticeNotifier;
  final DateTime Function() _clock;
  final LockSuppressionRunner _runWithLockSuppression;

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

  /// 退会実行前の再認証要否と利用可能な認証手段をチェックする
  Future<AccountDeletionPrecheck> checkReauthRequirement() async {
    if (_useFirebaseAuth) {
      final now = _clock();
      return AccountDeletionPrecheck(
        requiresReauthentication: _firebaseAuthRepository.needsRecentLogin(now),
        availableMethods: _firebaseAuthRepository.getAvailableReauthMethods(),
        email: _firebaseAuthRepository.currentUserEmail,
      );
    }

    // カスタム認証には最終ログイン時刻メタデータが無いため、退会前にパスワード再認証を求める
    final email = await _authRepository.getCurrentEmail();
    return AccountDeletionPrecheck(
      requiresReauthentication: true,
      availableMethods: const {ReauthMethod.password},
      email: email,
    );
  }

  /// パスワードによる再認証を実行する
  Future<void> reauthenticateWithPassword({
    required String password,
    String? email,
  }) async {
    if (_useFirebaseAuth) {
      await _firebaseAuthRepository.reauthenticateWithPassword(
        password: password,
      );
      return;
    }

    final resolvedEmail = (email != null && email.trim().isNotEmpty)
        ? email.trim()
        : await _authRepository.getCurrentEmail();
    if (resolvedEmail == null || resolvedEmail.isEmpty) {
      throw const ReauthMissingEmailException();
    }

    await _authRepository.reauthenticate(
      email: resolvedEmail,
      password: password,
    );
  }

  /// Googleアカウントによる再認証を実行する（外部認証UI往復中のアプリ誤ロックを抑止）
  Future<void> reauthenticateWithGoogle() async {
    if (!_useFirebaseAuth) {
      throw const AppException.unauthorized();
    }
    await _runWithLockSuppression(
      _firebaseAuthRepository.reauthenticateWithGoogle,
    );
  }

  /// アカウント完全退会フローを 4 段階で安全に実行する
  ///
  /// ① Firebase Storage アバター削除 ➔ ② サーバーDB削除 (DELETE /users/me)
  /// ➔ ③ Authアカウント削除 ➔ ④ ローカルデータ一括消去（メモ物理削除・QR履歴・usersキャッシュ）
  Future<void> deleteAccount() async {
    _talker.info(
      '[AuthService] deleteAccount started (useFirebase: $_useFirebaseAuth)',
    );

    // 0. 削除前に対象ユーザーIDとアバターURL候補を確保しておく
    final targetUserId = _useFirebaseAuth
        ? _firebaseAuthRepository.currentUserId
        : await _tokenStorage.getUserId();
    if (targetUserId == null || targetUserId.isEmpty) {
      throw const AppException.unauthenticated();
    }

    final avatarUrls = <String>{};
    if (_useFirebaseAuth) {
      final authPhotoUrl = _firebaseAuthRepository.currentUserPhotoUrl;
      if (authPhotoUrl != null && authPhotoUrl.isNotEmpty) {
        avatarUrls.add(authPhotoUrl);
      }
      try {
        final profile = await _profileRepository.fetchProfile();
        if (profile.avatarUrl.isNotEmpty) {
          avatarUrls.add(profile.avatarUrl);
        }
      } on Object catch (e, st) {
        if (_isNotFoundError(e)) {
          _talker.warning(
            '[AuthService] Profile not found before account deletion; '
            'skipping server avatar lookup.',
          );
        } else {
          _talker.handle(
            e,
            st,
            '[AuthService] Failed to fetch profile before account deletion',
          );
          rethrow;
        }
      }

      // ① Firebase Storage のアバター画像削除（非Storage URLや object-not-found は安全スキップ）
      for (final url in avatarUrls) {
        await _storageService.deleteAvatarByUrl(avatarUrl: url);
      }
    }

    // ② サーバーDB（プロフィール・メモ・レート制限）削除
    try {
      await _profileRepository.deleteMyAccountData();
    } on ReauthException {
      rethrow;
    } on Object catch (e, st) {
      _talker.handle(e, st, '[AuthService] Failed to delete server user data');
      rethrow;
    }

    // ③ Authアカウント削除
    // 認証解除直後に GoRouter が即座に /login へ遷移する競合を防ぐため、直前に通知フラグを立て、
    // 失敗時は即座に clear() する
    _accountDeletionNoticeNotifier.markCompleted();
    var shouldTerminateSession = true;
    try {
      if (_useFirebaseAuth) {
        await _firebaseAuthRepository.deleteAccount();
      } else {
        shouldTerminateSession = await _authStateNotifier.deleteAccount();
      }
    } on ReauthException {
      _accountDeletionNoticeNotifier.clear();
      rethrow;
    } on Object catch (e, st) {
      _accountDeletionNoticeNotifier.clear();
      _talker.handle(e, st, '[AuthService] Failed to delete auth account');
      rethrow;
    }

    if (!shouldTerminateSession) {
      // 削除待機中に別アカウントへ切り替わった場合は通知予約を取り消し、
      // 新セッションで使う共有データ（QR履歴・ユーザー一覧キャッシュ）は保持する
      _accountDeletionNoticeNotifier.clear();
    }

    // ④ ローカルデータ一括クリーンアップ
    // 既にサーバー側のAuth削除は完了しているため、失敗時はCrashlyticsへ記録しつつ
    // 残りの削除とサインアウト完了を継続する
    await _runLocalCleanupBestEffort(
      label: 'local memos',
      action: () => _memoRepository.deleteAllMemosByUser(targetUserId),
    );
    if (shouldTerminateSession) {
      await _runLocalCleanupBestEffort(
        label: 'QR scan histories',
        action: _qrScanHistoriesDao.deleteAllHistories,
      );
      await _runLocalCleanupBestEffort(
        label: 'users cache',
        action: () => _cacheManager.clear(UserRepository.cacheKey),
      );
    }

    // 退会完了イベント記録（Auth削除およびローカル削除完了後。送信失敗で退会自体は止めない）
    try {
      await _analyticsService.logEvent(event: AnalyticsEvent.accountDeleted);
    } on Object catch (e, st) {
      _talker.handle(
        e,
        st,
        '[AuthService] Failed to log accountDeleted analytics event',
      );
    }

    _talker.info('[AuthService] deleteAccount completed');
  }

  bool _isNotFoundError(Object error) {
    final actual = error is DioException ? (error.error ?? error) : error;
    return actual is BadRequestException && actual.statusCode == 404;
  }

  Future<void> _runLocalCleanupBestEffort({
    required String label,
    required Future<Object?> Function() action,
  }) async {
    try {
      await action();
    } on Object catch (e, st) {
      _talker.handle(
        e,
        st,
        '[AuthService] Failed to clean up $label after account deletion',
      );
    }
  }
}
