import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/ui/snackbar_extension.dart';
import 'package:go_router/go_router.dart';

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
    // 存在する l10n キーを使いつつ、足りないものは直接文字列で補完しています
    switch (error.code) {
      case 'invalid-email':
        return l10n.errorInvalidEmail;
      case 'user-disabled':
        return l10n.errorUserDisabled;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.errorLoginFailed;
      case 'email-already-in-use':
        return l10n.errorEmailAlreadyInUse;
      case 'weak-password':
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
