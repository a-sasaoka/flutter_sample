// 共通エラーメッセージをUIで表示するためのヘルパー関数
// Snackbar と Dialog の両方を用意しています。

import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';

/// エラーをSnackbarまたはDialogで表示する共通関数群
class ErrorHandler {
  /// 共通メッセージ変換
  static String message(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    return switch (error) {
      NetworkException(:final messageKey) => _localizeErrorKey(
        l10n,
        messageKey,
      ),
      TimeoutException() => l10n.errorTimeout,
      UnknownException(:final message) => message ?? l10n.errorUnknown,
      Object() => l10n.errorUnknown,
    };
  }

  static String _localizeErrorKey(AppLocalizations l10n, String key) {
    switch (key) {
      case 'errorNetwork':
        return l10n.errorNetwork;
      case 'errorTimeout':
        return l10n.errorTimeout;
      case 'errorUnknown':
        return l10n.errorUnknown;
      case 'errorServer':
        return l10n.errorServer;
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
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }
}
