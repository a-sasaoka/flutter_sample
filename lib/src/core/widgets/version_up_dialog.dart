import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart.dart';

/// バージョンアップダイアログの表示
class VersionUpDialog {
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
      await showDialog<void>(
        context: context,
        // キャンセル可能ならダイアログの外をタップしても閉じるようにする
        barrierDismissible: isCancelable,
        builder: (context) {
          return PopScope(
            canPop: isCancelable,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop && isCancelable) {
                ref.read(cancelControllerProvider.notifier).clickCancel();
              }
            },
            child: AlertDialog(
              title: Text(AppLocalizations.of(context)!.versionUpTitle),
              actions: [
                if (requestType == UpdateRequestType.cancelable)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(AppLocalizations.of(context)!.versionUpCancel),
                  ),
                TextButton(
                  onPressed: () {
                    // 本来であればここにStoreに飛ばす処理を書く
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.versionUpUpdate),
                ),
              ],
            ),
          );
        },
      );
    }
  }
}
