import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_deletion_notice_notifier.g.dart';

/// 退会完了後にログイン画面で完了SnackBarを表示するためのワンショット通知フラグ
///
/// 退会による認証解除直後に GoRouter が `/login` へリダイレクトすると、
/// `SnackBarNavigationObserver` が遷移前の SnackBar を消去するため、
/// 遷移先のログイン画面側で本フラグを消費して安全に通知を表示します。
@Riverpod(keepAlive: true)
class AccountDeletionNoticeNotifier extends _$AccountDeletionNoticeNotifier {
  @override
  bool build() => false;

  /// 退会完了通知を表示予定としてマークする
  void markCompleted() {
    state = true;
  }

  /// 退会完了通知フラグを消費し、表示すべきだった場合のみ true を返す
  bool consume() {
    if (!state) {
      return false;
    }
    state = false;
    return true;
  }

  /// 退会失敗時などに予約済みフラグをリセットする
  void clear() {
    state = false;
  }
}
