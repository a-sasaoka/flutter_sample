import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/core/network/logger_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
@riverpod
Stream<User?> authStateChanges(Ref ref) {
  // authStateChanges ではなく userChanges を使うことで、
  // user.reload() が呼ばれた時にも自動的にストリームが発火するようになります。
  return ref.watch(firebaseAuthProvider).userChanges();
}

/// Firebase Authenticationを使用した認証リポジトリ
@riverpod
FirebaseAuthRepository firebaseAuthRepository(Ref ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final googleSignIn = ref.watch(googleSignInProvider);
  return FirebaseAuthRepository(firebaseAuth, googleSignIn, ref);
}

/// Firebase Authenticationを使用した認証リポジトリの実装クラス
class FirebaseAuthRepository {
  /// コンストラクタ
  FirebaseAuthRepository(this._firebaseAuth, this._googleSignIn, this._ref);
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final Ref _ref;

  // Google認証初期化フラグ
  bool _googleSignInInitialized = false;

  // Google認証を初期化
  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;

    await _googleSignIn.initialize();

    _googleSignInInitialized = true;
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
      _ref.read(loggerProvider).w('SignInWithGoogle Error: $e');

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

  /// Firebase から現在のユーザー情報を再読み込みする
  Future<void> reloadCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  /// パスワードリセットメールを送信する
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// サインアウトする
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }
}
