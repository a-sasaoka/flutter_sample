import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';

/// バージョンアップダイアログの表示
class VersionUpDialog {
  // インスタンス化を防止するプライベートコンストラクタ
  VersionUpDialog._(); // coverage:ignore-line

  /// バージョンアップダイアログを表示
  static Future<void> show(
    BuildContext context,
    UpdateRequestType requestType,
    WidgetRef ref,
  ) async {
    // 新しいアプリバージョンあり、かつキャンセルしていない場合はダイアログを表示する
    if (requestType != UpdateRequestType.not &&
        !ref.read(cancelControllerProvider)) {
      final isCancelable = requestType == UpdateRequestType.cancelable;
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
                ref.read(cancelControllerProvider.notifier).clickCancel();
              }
            },
            child: AlertDialog(
              title: Text(l10n.versionUpTitle),
              actions: [
                if (isCancelable)
                  TextButton(
                    onPressed: () {
                      ref.read(cancelControllerProvider.notifier).clickCancel();
                      Navigator.pop(dialogContext); // dialogContext を使用
                    },
                    child: Text(l10n.versionUpCancel),
                  ),
                TextButton(
                  onPressed: () {
                    // 本来であればここにStoreに飛ばす処理を書く
                    Navigator.pop(dialogContext); // dialogContext を使用
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
}
