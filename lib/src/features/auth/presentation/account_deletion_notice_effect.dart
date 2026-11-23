import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/ui/snackbar_extension.dart';
import 'package:flutter_sample/src/features/auth/application/account_deletion_notice_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 退会確定後の完了SnackBar表示をログイン画面で制御する共通Hook
///
/// 退会による認証解除直後に GoRouter が `/login` へ遷移する場合、
/// `SnackBarNavigationObserver` による遷移前消去を防ぐため遷移先で表示する。
/// Auth削除が確定（[AccountDeletionNoticeStatus.completed]）するまでは
/// 予約（[AccountDeletionNoticeStatus.reserved]）状態であっても消費・表示しない。
void useAccountDeletionNoticeEffect(BuildContext context, WidgetRef ref) {
  void scheduleShowCompletedSnackBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final shouldShow = ref
          .read(accountDeletionNoticeProvider.notifier)
          .consume();
      if (shouldShow) {
        context.showSuccessSnackBar(context.l10n.accountDeletionCompleted);
      }
    });
  }

  // マウント時点で既に削除確定済みの場合に表示する
  useEffect(() {
    scheduleShowCompletedSnackBar();
    return null;
  }, const []);

  // 削除処理中にリダイレクトで先にログイン画面がマウントされた場合でも、
  // 後続で削除成功が確定（completed へ遷移）したタイミングで表示する
  ref.listen<AccountDeletionNoticeStatus>(accountDeletionNoticeProvider, (
    _,
    next,
  ) {
    if (next == AccountDeletionNoticeStatus.completed) {
      scheduleShowCompletedSnackBar();
    }
  });
}
