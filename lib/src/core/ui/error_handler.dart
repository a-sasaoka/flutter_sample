import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/ui/snackbar_extension.dart';
import 'package:go_router/go_router.dart';

/// Firebase Authentication の公式エラーコード文字列定数群
///
/// `FirebaseAuthException` の `code` プロパティと照合するために使用します。
/// 公式リファレンス: https://firebase.google.com/docs/auth/admin/errors
class FirebaseAuthErrorCodes {
  FirebaseAuthErrorCodes._(); // coverage:ignore-line

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
}

/// エラーをSnackbarまたはDialogで表示する共通関数群
class ErrorHandler {
  ErrorHandler._(); // coverage:ignore-line

  /// 共通メッセージ変換
  static String message(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;

    // DioException で包まれている場合は、中身の AppException を取り出す
    var actualError = error;
    if (error is DioException && error.error != null) {
      actualError = error.error!;
    }

    // AppException のエラー処理
    if (actualError is AppException) {
      if (actualError is UnknownException && actualError.message != null) {
        return actualError.message!;
      }
      return _localizeAppException(l10n, actualError);
    }

    // Firebase Authentication のエラー処理
    if (actualError is FirebaseAuthException) {
      return _localizeFirebaseAuthException(l10n, actualError);
    }

    // それ以外の一般エラー
    return l10n.errorUnknown;
  }

  /// AppExceptionの翻訳
  static String _localizeAppException(
    AppLocalizations l10n,
    AppException error,
  ) {
    return switch (error.type) {
      AppErrorType.network => l10n.errorNetwork,
      AppErrorType.timeout => l10n.errorTimeout,
      AppErrorType.server => l10n.errorServer,
      AppErrorType.unknown => l10n.errorUnknown,
    };
  }

  /// FirebaseAuthExceptionの翻訳
  static String _localizeFirebaseAuthException(
    AppLocalizations l10n,
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case FirebaseAuthErrorCodes.invalidEmail:
        return l10n.errorInvalidEmail;
      case FirebaseAuthErrorCodes.userDisabled:
        return l10n.errorUserDisabled;
      case FirebaseAuthErrorCodes.userNotFound:
      case FirebaseAuthErrorCodes.wrongPassword:
      case FirebaseAuthErrorCodes.invalidCredential:
        return l10n.errorLoginFailed;
      case FirebaseAuthErrorCodes.emailAlreadyInUse:
        return l10n.errorEmailAlreadyInUse;
      case FirebaseAuthErrorCodes.weakPassword:
        return l10n.errorWeakPassword;
      default:
        return l10n.errorUnknown;
    }
  }

  /// Snackbarで表示（軽度なエラー向け）
  static void showSnackBar(BuildContext context, Object error) {
    final messageText = message(context, error);
    context.showErrorSnackBar(messageText);
  }

  /// Dialogで表示（重要なエラーや確認が必要な場合）
  static Future<void> showDialogError(
    BuildContext context,
    Object error,
  ) async {
    final messageText = message(context, error);
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.errorDialogTitle),
        content: Text(messageText),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}
