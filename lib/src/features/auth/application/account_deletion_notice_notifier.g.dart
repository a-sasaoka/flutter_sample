// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_deletion_notice_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 退会完了後にログイン画面で完了SnackBarを表示するためのワンショット通知状態管理
///
/// 退会による認証解除直後に GoRouter が `/login` へリダイレクトすると、
/// `SnackBarNavigationObserver` が遷移前の SnackBar を消去するため、
/// 遷移先のログイン画面側で本状態を消費して安全に通知を表示します。
/// Auth削除失敗時に完了SnackBarが誤表示されるのを防ぐため、
/// 認証解除前に [reserve] で予約し、Auth削除の成功確定後にのみ [confirmCompleted] で
/// 表示可能な確定状態へ遷移させます。

@ProviderFor(AccountDeletionNoticeNotifier)
final accountDeletionNoticeProvider = AccountDeletionNoticeNotifierProvider._();

/// 退会完了後にログイン画面で完了SnackBarを表示するためのワンショット通知状態管理
///
/// 退会による認証解除直後に GoRouter が `/login` へリダイレクトすると、
/// `SnackBarNavigationObserver` が遷移前の SnackBar を消去するため、
/// 遷移先のログイン画面側で本状態を消費して安全に通知を表示します。
/// Auth削除失敗時に完了SnackBarが誤表示されるのを防ぐため、
/// 認証解除前に [reserve] で予約し、Auth削除の成功確定後にのみ [confirmCompleted] で
/// 表示可能な確定状態へ遷移させます。
final class AccountDeletionNoticeNotifierProvider
    extends
        $NotifierProvider<
          AccountDeletionNoticeNotifier,
          AccountDeletionNoticeStatus
        > {
  /// 退会完了後にログイン画面で完了SnackBarを表示するためのワンショット通知状態管理
  ///
  /// 退会による認証解除直後に GoRouter が `/login` へリダイレクトすると、
  /// `SnackBarNavigationObserver` が遷移前の SnackBar を消去するため、
  /// 遷移先のログイン画面側で本状態を消費して安全に通知を表示します。
  /// Auth削除失敗時に完了SnackBarが誤表示されるのを防ぐため、
  /// 認証解除前に [reserve] で予約し、Auth削除の成功確定後にのみ [confirmCompleted] で
  /// 表示可能な確定状態へ遷移させます。
  AccountDeletionNoticeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountDeletionNoticeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountDeletionNoticeNotifierHash();

  @$internal
  @override
  AccountDeletionNoticeNotifier create() => AccountDeletionNoticeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountDeletionNoticeStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountDeletionNoticeStatus>(value),
    );
  }
}

String _$accountDeletionNoticeNotifierHash() =>
    r'7ebb6e951fcd1ae91636db66031de7121e196330';

/// 退会完了後にログイン画面で完了SnackBarを表示するためのワンショット通知状態管理
///
/// 退会による認証解除直後に GoRouter が `/login` へリダイレクトすると、
/// `SnackBarNavigationObserver` が遷移前の SnackBar を消去するため、
/// 遷移先のログイン画面側で本状態を消費して安全に通知を表示します。
/// Auth削除失敗時に完了SnackBarが誤表示されるのを防ぐため、
/// 認証解除前に [reserve] で予約し、Auth削除の成功確定後にのみ [confirmCompleted] で
/// 表示可能な確定状態へ遷移させます。

abstract class _$AccountDeletionNoticeNotifier
    extends $Notifier<AccountDeletionNoticeStatus> {
  AccountDeletionNoticeStatus build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AccountDeletionNoticeStatus, AccountDeletionNoticeStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AccountDeletionNoticeStatus,
                AccountDeletionNoticeStatus
              >,
              AccountDeletionNoticeStatus,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
