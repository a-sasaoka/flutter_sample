import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_deletion_notice_notifier.g.dart';

/// 退会完了通知のライフサイクル状態
enum AccountDeletionNoticeStatus {
  /// 通知予約・確定なし
  none,

  /// 認証解除によるリダイレクトに備えた予約状態（Auth削除完了前のため表示・消費不可）
  reserved,

  /// Auth削除成功確定済み（ログイン画面でワンショット通知を表示・消費可能）
  completed,
}

/// 退会完了後にログイン画面で完了SnackBarを表示するためのワンショット通知状態管理
///
/// 退会による認証解除直後に GoRouter が `/login` へリダイレクトすると、
/// `SnackBarNavigationObserver` が遷移前の SnackBar を消去するため、
/// 遷移先のログイン画面側で本状態を消費して安全に通知を表示します。
/// Auth削除失敗時に完了SnackBarが誤表示されるのを防ぐため、
/// 認証解除前に [reserve] で予約し、Auth削除の成功確定後にのみ [confirmCompleted] で
/// 表示可能な確定状態へ遷移させます。
@Riverpod(keepAlive: true)
class AccountDeletionNoticeNotifier extends _$AccountDeletionNoticeNotifier {
  @override
  AccountDeletionNoticeStatus build() => AccountDeletionNoticeStatus.none;

  /// Authアカウント削除の直前に通知を予約状態へ進める
  ///
  /// まだ削除成功が確定していないため、この状態のままではログイン画面で消費できない。
  void reserve() {
    state = AccountDeletionNoticeStatus.reserved;
  }

  /// Authアカウント削除の成功確定を受けて完了通知を表示可能な状態にする
  ///
  /// 事前に [reserve] されている場合のみ [AccountDeletionNoticeStatus.completed] へ遷移する。
  void confirmCompleted() {
    if (state != AccountDeletionNoticeStatus.reserved) {
      return;
    }
    state = AccountDeletionNoticeStatus.completed;
  }

  /// 削除確定済みの完了通知を消費し、表示すべきだった場合のみ true を返す
  ///
  /// [AccountDeletionNoticeStatus.reserved] 中は消費せず false を返し、
  /// 後続の確定通知や失敗時のクリア判定へ影響を与えない。
  bool consume() {
    if (state != AccountDeletionNoticeStatus.completed) {
      return false;
    }
    state = AccountDeletionNoticeStatus.none;
    return true;
  }

  /// 退会失敗時や別アカウント切り替え時に通知状態（予約・確定）をリセットする
  void clear() {
    state = AccountDeletionNoticeStatus.none;
  }
}
