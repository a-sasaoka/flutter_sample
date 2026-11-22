import 'package:freezed_annotation/freezed_annotation.dart';

part 'reauth_exception.freezed.dart';

/// 再認証およびアカウント削除フローで発生する、ユーザー操作・フロー制御用の例外クラス (Union型)
///
/// これらはシステム障害（Crashlytics送信対象）ではなく、UI上での再認証誘導や
/// 入力エラーメッセージ表示として安全にハンドリングするために使用します。
/// （`talker.handle()` には渡さないこと）
@freezed
sealed class ReauthException with _$ReauthException implements Exception {
  /// 直近のログインが必要（`requires-recent-login`）な場合にスローされる例外
  const factory ReauthException.requiresRecentLogin() =
      ReauthRequiresRecentLoginException;

  /// 再認証時のパスワードが誤っている場合にスローされる例外
  const factory ReauthException.wrongPassword() = ReauthWrongPasswordException;

  /// 再認証時にログイン中とは別のアカウントが選択された場合にスローされる例外
  const factory ReauthException.userMismatch() = ReauthUserMismatchException;

  /// ユーザーによって再認証フローがキャンセルされた場合にスローされる例外
  const factory ReauthException.cancelled() = ReauthCancelledException;

  /// 短時間に再認証試行が集中し、レート制限に達した場合にスローされる例外
  const factory ReauthException.tooManyRequests() =
      ReauthTooManyRequestsException;

  /// パスワード再認証に必要なメールアドレスが現在のアカウントに設定されていない場合にスローされる例外
  const factory ReauthException.missingEmail() = ReauthMissingEmailException;
}
