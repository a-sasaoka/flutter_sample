import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';

/// アカウント削除 Step 1（影響範囲説明）ダイアログを表示するユーティリティ
abstract final class AccountDeletionStep1Dialog {
  /// Step 1 ダイアログを表示し、「続行」された場合のみ true を返す
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const AccountDeletionStep1DialogContent(),
    );
    return result ?? false;
  }
}

/// アカウント削除 Step 1 ダイアログの表示内容ウィジェット
///
/// ゴールデンテストで直接描画できるよう独立したウィジェットとして定義しています。
class AccountDeletionStep1DialogContent extends StatelessWidget {
  /// コンストラクタ
  const AccountDeletionStep1DialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: colorScheme.error,
        size: 36,
      ),
      title: Text(l10n.accountDeletionStep1Title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.accountDeletionStep1Description),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.accountDeletionItemAccount,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.accountDeletionItemProfile,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.accountDeletionItemMemos,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.accountDeletionItemHistory,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('account_deletion_step1_cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('account_deletion_step1_continue'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.accountDeletionStep1Continue),
        ),
      ],
    );
  }
}

/// アカウント削除 Step 2（最終確認）ダイアログを表示するユーティリティ
abstract final class AccountDeletionStep2Dialog {
  /// Step 2 ダイアログを表示し、最終確認された場合のみ true を返す
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const AccountDeletionStep2DialogContent(),
    );
    return result ?? false;
  }
}

/// アカウント削除 Step 2（最終確認）ダイアログの表示内容ウィジェット
class AccountDeletionStep2DialogContent extends StatelessWidget {
  /// コンストラクタ
  const AccountDeletionStep2DialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(
        Icons.delete_forever_outlined,
        color: colorScheme.error,
        size: 36,
      ),
      title: Text(l10n.accountDeletionStep2Title),
      content: Text(l10n.accountDeletionStep2Description),
      actions: [
        TextButton(
          key: const Key('account_deletion_step2_cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('account_deletion_step2_confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.accountDeletionStep2Confirm),
        ),
      ],
    );
  }
}

/// アカウント削除実行中のローディングダイアログ表示内容ウィジェット
class AccountDeletionProcessingDialogContent extends StatelessWidget {
  /// コンストラクタ
  const AccountDeletionProcessingDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: const Key('account_deletion_processing_dialog'),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(l10n.accountDeletionProcessing)),
          ],
        ),
      ),
    );
  }
}
