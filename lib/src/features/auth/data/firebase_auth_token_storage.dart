import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/core/storage/token_storage.dart';

/// Firebase AuthenticationからIDトークンを取得する専用のストレージクラス
class FirebaseAuthTokenStorage implements TokenStorage {
  /// コンストラクタ
  FirebaseAuthTokenStorage(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  @override
  Future<String?> getAccessToken() async {
    // ログイン中のユーザーから最新のIDトークンを取得します
    return _firebaseAuth.currentUser?.getIdToken();
  }

  @override
  Future<String?> getRefreshToken() async {
    // FirebaseではSDKが自動でリフレッシュするため、リフレッシュトークンは個別管理不要です
    return null;
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    // Firebaseが自動保存するため、ここでは何もしません
  }

  @override
  Future<void> clear() async {
    // ログアウト処理は FirebaseAuthRepository が行うため、ここでは何もしません
  }
}
