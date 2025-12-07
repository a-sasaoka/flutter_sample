import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_auth_repository.g.dart';

/// Firebase Authenticationを使用した認証リポジトリ
@riverpod
class FirebaseAuthRepository extends _$FirebaseAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  User? build() {
    // 現在ログインしているユーザーを返す
    return _auth.currentUser;
  }

  /// 認証状態の変更を監視するストリームを返す
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// メールアドレスとパスワードでログインする
  Future<void> signIn(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // ログインした情報でstateを更新
    state = userCredential.user;
  }

  /// メールアドレスとパスワードで新規登録する
  Future<void> signUp(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 登録した情報でstateを更新
    state = userCredential.user;
  }

  /// サインアウトする
  Future<void> signOut() async {
    await _auth.signOut();

    // stateをnullで初期化
    state = null;
  }
}
