// 共通エラーメッセージをUIで表示するためのヘルパー関数
// Snackbar と Dialog の両方を用意しています。

import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';

/// エラーをSnackbarまたはDialogで表示する共通関数群
class ErrorHandler {
  /// 共通メッセージ変換
  static String message(BuildContext context, Object error) {
    final t = AppLocalizations.of(context)!;
    return switch (error) {
      NetworkException(:final messageKey) => _localizeErrorKey(t, messageKey),
      TimeoutException() => t.errorTimeout,
      UnknownException(:final message) => message ?? t.errorUnknown,
      Object() => t.errorUnknown,
    };
  }

  static String _localizeErrorKey(AppLocalizations t, String key) {
    switch (key) {
      case 'errorNetwork':
        return t.errorNetwork;
      case 'errorTimeout':
        return t.errorTimeout;
      case 'errorUnknown':
        return t.errorUnknown;
      case 'errorServer':
        return t.errorServer;
      default:
        return key;
    }
  }

  /// Snackbarで表示（軽度なエラー向け）
  static void showSnackBar(BuildContext context, Object error) {
    final messageText = message(context, error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messageText),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Dialogで表示（重要なエラーや確認が必要な場合）
  static Future<void> showDialogError(
    BuildContext context,
    Object error,
  ) async {
    final messageText = message(context, error);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.errorDialogTitle),
        content: Text(messageText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
