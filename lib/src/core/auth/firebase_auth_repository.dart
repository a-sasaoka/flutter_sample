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
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// メールアドレスとパスワードで新規登録する
  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// サインアウトする
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
