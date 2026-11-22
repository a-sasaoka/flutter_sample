import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/exceptions/firebase_auth_error_codes.dart';
import 'package:flutter_sample/src/core/exceptions/reauth_exception.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/domain/account_deletion_precheck.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'firebase_auth_repository.g.dart';

// coverage:ignore-start
/// Firebase Authenticationのインスタンスを返す
@riverpod
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

/// Google Sign Inのインスタンスを返す
@riverpod
GoogleSignIn googleSignIn(Ref ref) => GoogleSignIn.instance;
// coverage:ignore-end

/// Firebase Authenticationの認証状態（ユーザー変更含む）を監視するプロバイダー
@Riverpod(keepAlive: true)
Stream<User?> authStateChanges(Ref ref) {
  // authStateChanges ではなく userChanges を使うことで、
  // user.reload() が呼ばれた時にも自動的にストリームが発火するようになります。
  return ref.watch(firebaseAuthProvider).userChanges();
}

/// Firebase Authenticationを使用した認証リポジトリ
@riverpod
FirebaseAuthRepository firebaseAuthRepository(Ref ref) {
  return FirebaseAuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
    talker: ref.watch(loggerProvider),
  );
}

/// Firebase Authenticationを使用した認証リポジトリの実装クラス
class FirebaseAuthRepository {
  /// コンストラクタ
  FirebaseAuthRepository({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required Talker talker,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn,
       _talker = talker;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final Talker _talker;

  // Google認証の初期化状態（インスタンス単位で共有し、リポジトリ再生成時の二重初期化を防ぐ）
  static final Expando<Future<void>> _googleSignInInitFutures =
      Expando<Future<void>>('googleSignInInit');

  // Google認証をインスタンス単位で1回だけ初期化する
  Future<void> _ensureGoogleSignInInitialized() async {
    final future = _googleSignInInitFutures[_googleSignIn] ??= _googleSignIn
        .initialize();
    try {
      await future;
    } on Object {
      // 初期化に失敗した場合は次回呼び出しで再試行できるよう状態をクリアする
      _googleSignInInitFutures[_googleSignIn] = null;
      rethrow;
    }
  }

  /// メールアドレスとパスワードでログインする
  Future<void> signIn(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Googleアカウントでログインする
  Future<bool> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    try {
      final googleUser = await _googleSignIn.authenticate();

      // ID token 取得
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      final authz = await googleUser.authorizationClient.authorizationForScopes(
        const <String>['https://www.googleapis.com/auth/userinfo.email'],
      );

      // Access token 取得
      final accessToken = authz?.accessToken;

      if (idToken == null && accessToken == null) {
        return false;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);

      return true;
    } on Exception catch (e) {
      _talker.warning('SignInWithGoogle Error: $e');

      // ユーザーキャンセル等もここに入ることがあります
      return false;
    }
  }

  /// メールアドレスとパスワードで新規登録する
  Future<void> signUp(String email, String password) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// 未認証ユーザーに確認メールを送信する
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// 現在ログイン中のユーザーID（未ログイン時はnull）
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Firebase から現在のユーザー情報を再読み込みする
  Future<void> reloadCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  /// Firebase Auth の現在のユーザー情報（表示名、メールアドレス、写真URL）を更新して再読み込みする
  Future<void> updateAuthProfile({
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      _talker.debug(
        'Updating Firebase user: displayName=$displayName, email=$email, '
        'photoUrl=$photoUrl',
      );
      // 表示名が変更されている場合のみ更新する
      if (user.displayName != displayName) {
        await user.updateDisplayName(displayName);
      }
      // メールアドレスが変更されている場合のみ更新要求を送る
      if (user.email != email) {
        await user.verifyBeforeUpdateEmail(email);
      }
      // 写真URLが変更されている場合のみ更新する
      if (photoUrl != null && user.photoURL != photoUrl) {
        await user.updatePhotoURL(photoUrl.isEmpty ? null : photoUrl);
      }
      await user.reload();
      _talker.debug('Successfully updated and reloaded Firebase user.');
    } else {
      _talker.warning(
        'Cannot update Firebase profile: No user is currently signed in.',
      );
      throw const AppException.unauthenticated();
    }
  }

  /// パスワードリセットメールを送信する
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// サインアウトする
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _ensureGoogleSignInInitialized();
    await _googleSignIn.signOut();
  }

  /// 現在ログイン中ユーザーのメールアドレス（未ログイン時はnull）
  String? get currentUserEmail => _firebaseAuth.currentUser?.email;

  /// 現在ログイン中ユーザーの写真URL（未ログイン時はnull）
  String? get currentUserPhotoUrl => _firebaseAuth.currentUser?.photoURL;

  /// 現在ログイン中ユーザーの最終ログイン時刻（未取得時はnull）
  DateTime? get lastSignInTime =>
      _firebaseAuth.currentUser?.metadata.lastSignInTime;

  /// 現在ログイン中ユーザーに紐づく再認証手段の一覧を返す
  Set<ReauthMethod> getAvailableReauthMethods() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const <ReauthMethod>{};
    }

    final methods = <ReauthMethod>{};
    for (final info in user.providerData) {
      if (info.providerId == EmailAuthProvider.PROVIDER_ID) {
        methods.add(ReauthMethod.password);
      } else if (info.providerId == GoogleAuthProvider.PROVIDER_ID) {
        methods.add(ReauthMethod.google);
      }
    }
    return methods;
  }

  /// 最終ログイン時刻から一定時間（既定5分）以上経過しているか判定する
  ///
  /// 最終ログイン時刻が取得できない（null）場合も安全側（再認証必要）として true を返します。
  bool needsRecentLogin(
    DateTime now, {
    Duration maxAge = const Duration(minutes: 5),
  }) {
    final signedInAt = lastSignInTime;
    if (signedInAt == null) {
      return true;
    }
    return now.toUtc().difference(signedInAt.toUtc()) > maxAge;
  }

  /// メールアドレスとパスワードで再認証する
  Future<void> reauthenticateWithPassword({required String password}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException.unauthenticated();
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const ReauthMissingEmailException();
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _mapReauthFirebaseException(e, method: ReauthMethod.password);
    }
  }

  /// Googleアカウントで再認証する
  ///
  /// キャンセル時は [ReauthCancelledException]、別アカウント選択時は
  /// [ReauthUserMismatchException] をスローします。
  Future<void> reauthenticateWithGoogle() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException.unauthenticated();
    }

    await _ensureGoogleSignInInitialized();

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        _talker.info('Google re-authentication was cancelled: ${e.code}');
        throw const ReauthCancelledException();
      }
      if (e.code == GoogleSignInExceptionCode.userMismatch) {
        _talker.warning('Google re-authentication failed: userMismatch');
        throw const ReauthUserMismatchException();
      }
      rethrow;
    }

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    final authz = await googleUser.authorizationClient.authorizationForScopes(
      const <String>['https://www.googleapis.com/auth/userinfo.email'],
    );
    final accessToken = authz?.accessToken;

    if (idToken == null && accessToken == null) {
      _talker.info('Google re-authentication returned no tokens.');
      throw const ReauthCancelledException();
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );

    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _mapReauthFirebaseException(e, method: ReauthMethod.google);
    }
  }

  /// Firebase Auth の現在ユーザーを削除し、Googleサインインセッションも終了する
  ///
  /// 最終ログインからの経過等で `requires-recent-login` が返った場合は
  /// [ReauthRequiresRecentLoginException] をスローします。
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException.unauthenticated();
    }

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == FirebaseAuthErrorCodes.requiresRecentLogin) {
        _talker.warning('Firebase deleteAccount requires recent login.');
        throw const ReauthRequiresRecentLoginException();
      }
      rethrow;
    }

    try {
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    } on Object catch (e, st) {
      // Auth削除は既に完了しているため、Googleサインアウト失敗はCrashlyticsへ記録して続行する
      _talker.handle(
        e,
        st,
        'Failed to sign out Google session after account deletion',
      );
    }
  }

  Exception _mapReauthFirebaseException(
    FirebaseAuthException e, {
    required ReauthMethod method,
  }) {
    return switch (e.code) {
      FirebaseAuthErrorCodes.wrongPassword => () {
        _talker.warning('Firebase reauth failed: ${e.code}');
        return const ReauthWrongPasswordException();
      }(),
      FirebaseAuthErrorCodes.invalidCredential => () {
        _talker.warning('Firebase reauth failed (${method.name}): ${e.code}');
        return switch (method) {
          ReauthMethod.password => const ReauthWrongPasswordException(),
          ReauthMethod.google => const ReauthInvalidCredentialException(),
        };
      }(),
      FirebaseAuthErrorCodes.userMismatch => () {
        _talker.warning('Firebase reauth failed: user-mismatch');
        return const ReauthUserMismatchException();
      }(),
      FirebaseAuthErrorCodes.tooManyRequests => () {
        _talker.warning('Firebase reauth failed: too-many-requests');
        return const ReauthTooManyRequestsException();
      }(),
      FirebaseAuthErrorCodes.requiresRecentLogin => () {
        _talker.warning('Firebase reauth failed: requires-recent-login');
        return const ReauthRequiresRecentLoginException();
      }(),
      _ => e,
    };
  }
}
