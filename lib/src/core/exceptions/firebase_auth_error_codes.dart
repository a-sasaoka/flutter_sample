/// Firebase Authentication の公式エラーコード文字列定数群
///
/// `FirebaseAuthException` の `code` プロパティと照合するために使用します。
/// 公式リファレンス: https://firebase.google.com/docs/auth/admin/errors
abstract final class FirebaseAuthErrorCodes {
  /// メールアドレスの形式が不正な場合にスローされます。
  /// （例: `@` が含まれていない、ドメインがない など）
  static const invalidEmail = 'invalid-email';

  /// 該当するユーザーアカウントが、Firebaseコンソール等で
  /// 管理者によって「無効（Disabled）」に設定されている場合にスローされます。
  static const userDisabled = 'user-disabled';

  /// 指定された識別子（メールアドレス等）に対応するユーザーが存在しない場合にスローされます。
  /// ※最近のFirebaseでは、セキュリティ向上のため `invalid-credential` に統合される傾向があります。
  static const userNotFound = 'user-not-found';

  /// パスワードが間違っている場合にスローされます。
  /// ※最近のFirebaseでは、セキュリティ向上のため `invalid-credential` に統合される傾向があります。
  static const wrongPassword = 'wrong-password';

  /// 認証情報（メールアドレスとパスワードの組み合わせなど）が間違っている、
  /// または有効期限が切れている場合にスローされます。
  /// （セキュリティ上、「メアドがない」のか「パスワードが違う」のかを攻撃者に教えないための汎用エラーです）
  static const invalidCredential = 'invalid-credential';

  /// 新規登録時、指定したメールアドレスが既に別のアカウントで使用されている場合にスローされます。
  static const emailAlreadyInUse = 'email-already-in-use';

  /// 新規登録時、指定したパスワードがFirebaseの要件（通常は6文字以上）を
  /// 満たしておらず、弱すぎる場合にスローされます。
  static const weakPassword = 'weak-password';

  /// 再ログインから一定時間が経過しており、重要操作（退会・パスワード変更等）の
  /// 前に再認証が必要な場合にスローされます。
  static const requiresRecentLogin = 'requires-recent-login';

  /// 再認証時などに、現在ログイン中のアカウントとは別のアカウント
  /// （別メールアドレス・別Googleアカウント等）で認証しようとした場合にスローされます。
  static const userMismatch = 'user-mismatch';

  /// 短時間に試行が集中し、Firebase Auth のレート制限に達した場合にスローされます。
  static const tooManyRequests = 'too-many-requests';
}
