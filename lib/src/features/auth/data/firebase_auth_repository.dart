import 'package:firebase_auth/firebase_auth.dart';
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

/// Firebase Authenticationを使用した認証リポジトリ
@riverpod
class FirebaseAuthRepository extends _$FirebaseAuthRepository {
  // Google認証初期化フラグ
  bool _googleSignInInitialized = false;

  // Google認証を初期化
  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;

    await ref.read(googleSignInProvider).initialize();

    _googleSignInInitialized = true;
  }

  @override
  User? build() {
    // 現在ログインしているユーザーを返す
    return ref.read(firebaseAuthProvider).currentUser;
  }

  /// 認証状態の変更を監視するストリームを返す
  Stream<User?> authStateChanges() =>
      ref.read(firebaseAuthProvider).authStateChanges();

  /// メールアドレスとパスワードでログインする
  Future<void> signIn(String email, String password) async {
    final userCredential = await ref
        .read(firebaseAuthProvider)
        .signInWithEmailAndPassword(
          email: email,
          password: password,
        );

    // ログインした情報でstateを更新
    state = userCredential.user;
  }

  /// Googleアカウントでログインする
  Future<bool> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    try {
      final googleUser = await ref.read(googleSignInProvider).authenticate();

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

      final userCredential = await ref
          .read(firebaseAuthProvider)
          .signInWithCredential(credential);

      // ログインした情報でstateを更新
      state = userCredential.user;
      return true;
    } on Exception {
      // ユーザーキャンセル等もここに入ることがあります
      return false;
    }
  }

  /// メールアドレスとパスワードで新規登録する
  Future<void> signUp(String email, String password) async {
    final userCredential = await ref
        .read(firebaseAuthProvider)
        .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

    // 登録した情報でstateを更新
    state = userCredential.user;
  }

  /// 未認証ユーザーに確認メールを送信する
  Future<void> sendEmailVerification() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Firebase から現在のユーザー情報を再読み込みする
  Future<void> reloadCurrentUser() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      await user.reload();
      // reload後の最新ユーザー情報でstateを更新
      state = ref.read(firebaseAuthProvider).currentUser;
    }
  }

  /// パスワードリセットメールを送信する
  Future<void> sendPasswordResetEmail(String email) async {
    await ref.read(firebaseAuthProvider).sendPasswordResetEmail(email: email);
  }

  /// サインアウトする
  Future<void> signOut() async {
    await ref.read(firebaseAuthProvider).signOut();
    await ref.read(googleSignInProvider).signOut();

    // stateをnullで初期化
    state = null;
  }
}
