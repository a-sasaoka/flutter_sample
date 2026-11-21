/// 再認証およびアカウント削除フローで発生する、ユーザー操作・フロー制御用の例外クラス
///
/// これらはシステム障害（Crashlytics送信対象）ではなく、UI上での再認証誘導や
/// 入力エラーメッセージ表示として安全にハンドリングするために使用します。
/// （`talker.handle()` には渡さないこと）
sealed class ReauthException implements Exception {
  /// コンストラクタ
  const ReauthException();
}

/// 直近のログインが必要（`requires-recent-login`）な場合にスローされる例外
final class ReauthRequiresRecentLoginException extends ReauthException {
  /// コンストラクタ
  const ReauthRequiresRecentLoginException();
}

/// 再認証時のパスワードが誤っている場合にスローされる例外
final class ReauthWrongPasswordException extends ReauthException {
  /// コンストラクタ
  const ReauthWrongPasswordException();
}

/// 再認証時にログイン中とは別のアカウントが選択された場合にスローされる例外
final class ReauthUserMismatchException extends ReauthException {
  /// コンストラクタ
  const ReauthUserMismatchException();
}

/// ユーザーによって再認証フローがキャンセルされた場合にスローされる例外
final class ReauthCancelledException extends ReauthException {
  /// コンストラクタ
  const ReauthCancelledException();
}

/// 短時間に再認証試行が集中し、レート制限に達した場合にスローされる例外
final class ReauthTooManyRequestsException extends ReauthException {
  /// コンストラクタ
  const ReauthTooManyRequestsException();
}

/// パスワード再認証に必要なメールアドレスが現在のアカウントに設定されていない場合にスローされる例外
final class ReauthMissingEmailException extends ReauthException {
  /// コンストラクタ
  const ReauthMissingEmailException();
}
