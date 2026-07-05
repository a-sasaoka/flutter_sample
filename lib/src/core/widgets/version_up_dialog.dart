import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';

/// バージョンアップダイアログのアクション結果を表す列挙型
enum VersionUpDialogResult {
  /// アップデートを実行
  update,

  /// キャンセル
  cancel,
}

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
    // 💡 ダイアログのポップ結果を受け取ります。
    final result = await showDialog<VersionUpDialogResult>(
      context: context,
      // キャンセル可能ならダイアログの外をタップしても閉じるようにする
      barrierDismissible: isCancelable,
      builder: (dialogContext) {
        return VersionUpDialogContent(
          isCancelable: isCancelable,
        );
      },
    );

    // 💡 結果に応じて適切なコールバックを1回のみ呼び出します。
    if (result == VersionUpDialogResult.update) {
      onUpdate();
    } else {
      // result が cancel または null (ダイアログ外タップやシステムの戻るボタン) の場合
      onCancel();
    }
  }
}

/// バージョンアップダイアログの表示内容を定義するウィジェット
///
/// ゴールデンテストで直接描画できるように公開クラスとして定義します。
class VersionUpDialogContent extends StatelessWidget {
  /// バージョンアップダイアログの表示内容を構築します。
  const VersionUpDialogContent({
    required this.isCancelable,
    super.key,
  });

  /// キャンセル可能かどうか（キャンセルボタンを表示し、ダイアログ外タップで閉じることを許可するか）
  final bool isCancelable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopScope(
      canPop: isCancelable,
      // 💡 ポップ完了後の処理自体は show 側で一元管理するため、ここでの callback 呼び出しは不要です。
      // ただし PopScope は isCancelable が false の時に
      // ダイアログを閉じさせない（canPop: false）ために維持します。
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
                // 💡 キャンセル結果を明示してポップします
                Navigator.of(context).pop(VersionUpDialogResult.cancel);
              },
              child: Text(l10n.versionUpCancel),
            ),
          TextButton(
            onPressed: () {
              // 💡 アップデート結果を明示してポップします
              Navigator.of(context).pop(VersionUpDialogResult.update);
            },
            child: Text(l10n.versionUpUpdate),
          ),
        ],
      ),
    );
  }
}
