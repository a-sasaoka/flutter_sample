import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';

/// バージョンアップダイアログの表示
abstract final class VersionUpDialog {
  /// バージョンアップダイアログを表示
  ///
  /// [isCancelable] が true の場合、キャンセルボタンを表示し、ダイアログ外タップでも閉じられます。
  /// [onUpdate] はアップデートボタン押下時に呼ばれます。
  /// [onCancel] はキャンセル時（ボタンまたはダイアログを閉じた時）に呼ばれます。
  static Future<void> show(
    BuildContext context, {
    required bool isCancelable,
    required VoidCallback onUpdate,
    required VoidCallback onCancel,
  }) async {
    await showDialog<void>(
      context: context,
      // キャンセル可能ならダイアログの外をタップしても閉じるようにする
      barrierDismissible: isCancelable,
      builder: (dialogContext) {
        return VersionUpDialogContent(
          isCancelable: isCancelable,
          onUpdate: onUpdate,
          onCancel: onCancel,
        );
      },
    );
  }
}

/// バージョンアップダイアログの表示内容を定義するウィジェット
///
/// ゴールデンテストで直接描画できるように公開クラスとして定義します。
class VersionUpDialogContent extends StatelessWidget {
  /// バージョンアップダイアログの表示内容を構築します。
  const VersionUpDialogContent({
    required this.isCancelable,
    required this.onUpdate,
    required this.onCancel,
    super.key,
  });

  /// キャンセル可能かどうか（キャンセルボタンを表示し、ダイアログ外タップで閉じることを許可するか）
  final bool isCancelable;

  /// アップデートボタン押下時に呼ばれるコールバック
  final VoidCallback onUpdate;

  /// キャンセル時（キャンセルボタン押下時またはダイアログが閉じられた時）に呼ばれるコールバック
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopScope(
      canPop: isCancelable,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && isCancelable) {
          onCancel();
        }
      },
      child: AlertDialog(
        title: Text(l10n.versionUpTitle),
        content: Text(
          isCancelable
              ? l10n.versionUpMessageOptional
              : l10n.versionUpMessageMandatory,
        ),
        actions: [
          if (isCancelable)
            TextButton(
              onPressed: () {
                onCancel();
                Navigator.of(context).pop();
              },
              child: Text(l10n.versionUpCancel),
            ),
          TextButton(
            onPressed: () {
              onUpdate();
              // ストア等に遷移する場合は通常アプリを離れるが、
              // テストやUIの挙動としてダイアログを閉じる処理を入れておく
              Navigator.of(context).pop();
            },
            child: Text(l10n.versionUpUpdate),
          ),
        ],
      ),
    );
  }
}
