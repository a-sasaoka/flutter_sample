import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// バージョンアップダイアログの表示
class VersionUpDialog {
  // インスタンス化を防止するプライベートコンストラクタ
  VersionUpDialog._(); // coverage:ignore-line

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
    final l10n = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      // キャンセル可能ならダイアログの外をタップしても閉じるようにする
      barrierDismissible: isCancelable,
      builder: (dialogContext) {
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
                    dialogContext.pop();
                  },
                  child: Text(l10n.versionUpCancel),
                ),
              TextButton(
                onPressed: () {
                  onUpdate();
                  // ストア等に遷移する場合は通常アプリを離れるが、
                  // テストやUIの挙動としてダイアログを閉じる処理を入れておく
                  dialogContext.pop();
                },
                child: Text(l10n.versionUpUpdate),
              ),
            ],
          ),
        );
      },
    );
  }
}
