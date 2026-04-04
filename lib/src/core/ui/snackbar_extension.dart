import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';

/// スナックバーの種類
enum SnackBarType {
  /// インフォメーション
  info,

  /// 成功
  success,

  /// エラー
  error,
}

/// BuildContextの拡張メソッドとしてスナックバーを定義
extension SnackBarExtension on BuildContext {
  /// 汎用スナックバーを表示するメソッド
  void showSnackBar(
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final l10n = AppLocalizations.of(this)!;

    // 連続でタップされた時に、前のスナックバーを消してすぐ次を表示する
    ScaffoldMessenger.of(this).hideCurrentSnackBar();

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getIcon(type), color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: _getBackgroundColor(type),
        duration: duration,
        behavior: SnackBarBehavior.floating, // 画面下部から少し浮かす
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: l10n.close,
          textColor: Colors.white70,
          onPressed: () {
            ScaffoldMessenger.of(this).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 成功用のショートカットメソッド
  void showSuccessSnackBar(String message) {
    showSnackBar(message, type: SnackBarType.success);
  }

  /// エラー用のショートカットメソッド
  void showErrorSnackBar(String message) {
    showSnackBar(message, type: SnackBarType.error);
  }

  Color _getBackgroundColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.info:
        return Colors.grey.shade800;
      case SnackBarType.success:
        return Colors.green.shade700;
      case SnackBarType.error:
        return Colors.red.shade700;
    }
  }

  IconData _getIcon(SnackBarType type) {
    switch (type) {
      case SnackBarType.info:
        return Icons.info_outline;
      case SnackBarType.success:
        return Icons.check_circle_outline;
      case SnackBarType.error:
        return Icons.error_outline;
    }
  }
}
