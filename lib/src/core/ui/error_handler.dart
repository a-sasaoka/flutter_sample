// lib/src/core/ui/error_handler.dart
// 共通エラーメッセージをUIで表示するためのヘルパー関数
// Snackbar と Dialog の両方を用意しています。

import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';

/// エラーをSnackbarまたはDialogで表示する共通関数群
class ErrorHandler {
  /// 共通メッセージ変換
  static String message(Object error) {
    return switch (error) {
      NetworkException(:final message) => message,
      TimeoutException() => '通信がタイムアウトしました。',
      UnknownException(:final message) => message,
      Object() => '予期しないエラーが発生しました。',
    };
  }

  /// Snackbarで表示（軽度なエラー向け）
  static void showSnackBar(BuildContext context, Object error) {
    final messageText = message(error);
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
    final messageText = message(error);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('エラーが発生しました'),
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
