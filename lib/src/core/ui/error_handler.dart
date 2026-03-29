// 共通エラーメッセージをUIで表示するためのヘルパー関数
// Snackbar と Dialog の両方を用意しています。

import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';

/// エラーをSnackbarまたはDialogで表示する共通関数群
class ErrorHandler {
  // インスタンス化を防止するプライベートコンストラクタ
  ErrorHandler._(); // coverage:ignore-line

  /// 共通メッセージ変換
  static String message(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;

    // 1. UnknownException かつ カスタムメッセージがある場合のみ例外的に扱う
    if (error is UnknownException && error.message != null) {
      return error.message!;
    }

    // 2. AppException であれば、その messageKey を使って多言語化する
    if (error is AppException) {
      return _localizeErrorKey(l10n, error.messageKey);
    }

    // 3. それ以外の一般エラー（Object）
    return l10n.errorUnknown;
  }

  static String _localizeErrorKey(AppLocalizations l10n, String key) {
    return switch (key) {
      'errorNetwork' => l10n.errorNetwork,
      'errorTimeout' => l10n.errorTimeout,
      'errorUnknown' => l10n.errorUnknown,
      'errorServer' => l10n.errorServer,
      _ => key, // 未定義のキーはそのまま返す（フォールバック）
    };
  }

  /// Snackbarで表示（軽度なエラー向け）
  static void showSnackBar(BuildContext context, Object error) {
    final messageText = message(context, error);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar() // 前のスナックバーを消して即座に新しいものを表示
      ..showSnackBar(
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
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.errorDialogTitle),
        content: Text(messageText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // ダイアログのコンテキストを使用
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}
