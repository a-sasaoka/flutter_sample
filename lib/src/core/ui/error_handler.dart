import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/exceptions/firebase_auth_error_codes.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/ui/snackbar_extension.dart';
import 'package:go_router/go_router.dart';

/// エラーをSnackbarまたはDialogで表示する共通関数群
abstract final class ErrorHandler {
  /// 共通メッセージ変換
  static String message(BuildContext context, Object error) {
    final l10n = context.l10n;

    // DioException で包まれている場合は、中身の AppException を取り出す
    var actualError = error;
    if (error is DioException) {
      if (error.error case final Object err) {
        actualError = err;
      }
    }

    // AppException のエラー処理
    if (actualError is AppException) {
      final baseMessage = switch (actualError) {
        NetworkException(:final message) => message ?? l10n.errorNetwork,
        ServerException(:final message) => message ?? l10n.errorServer,
        BadRequestException(:final message) => message ?? l10n.errorBadRequest,
        UnauthenticatedException(:final message) =>
          message ?? l10n.errorUnauthenticated,
        UnauthorizedException(:final message) =>
          message ?? l10n.errorUnauthorized,
        TimeoutException(:final message) => message ?? l10n.errorTimeout,
        DataParseException(:final message) => message ?? l10n.errorDataParse,
        DatabaseException(:final message) => message ?? l10n.errorDatabase,
        CancelException(:final message) => message ?? l10n.errorUnknown,
        UnknownException(:final message) => message ?? l10n.errorUnknown,
      };

      // ステータスコードがあれば付与する (デバッグや詳細確認用)
      final statusCode = actualError.statusCode;
      return statusCode != null ? '$baseMessage ($statusCode)' : baseMessage;
    }

    // Firebase Authentication のエラー処理
    if (actualError is FirebaseAuthException) {
      return _localizeFirebaseAuthException(l10n, actualError);
    }

    // それ以外の一般エラー
    return l10n.errorUnknown;
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
    final l10n = context.l10n;

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
