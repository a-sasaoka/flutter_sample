// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_deletion_notice_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 退会完了後にログイン画面で完了SnackBarを表示するためのワンショット通知フラグ
///
/// 退会による認証解除直後に GoRouter が `/login` へリダイレクトすると、
/// `SnackBarNavigationObserver` が遷移前の SnackBar を消去するため、
/// 遷移先のログイン画面側で本フラグを消費して安全に通知を表示します。

@ProviderFor(AccountDeletionNoticeNotifier)
final accountDeletionNoticeProvider = AccountDeletionNoticeNotifierProvider._();

/// 退会完了後にログイン画面で完了SnackBarを表示するためのワンショット通知フラグ
///
/// 退会による認証解除直後に GoRouter が `/login` へリダイレクトすると、
/// `SnackBarNavigationObserver` が遷移前の SnackBar を消去するため、
/// 遷移先のログイン画面側で本フラグを消費して安全に通知を表示します。
final class AccountDeletionNoticeNotifierProvider
    extends $NotifierProvider<AccountDeletionNoticeNotifier, bool> {
  /// 退会完了後にログイン画面で完了SnackBarを表示するためのワンショット通知フラグ
  ///
  /// 退会による認証解除直後に GoRouter が `/login` へリダイレクトすると、
  /// `SnackBarNavigationObserver` が遷移前の SnackBar を消去するため、
  /// 遷移先のログイン画面側で本フラグを消費して安全に通知を表示します。
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
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$accountDeletionNoticeNotifierHash() =>
    r'4d54da2338a8b556dd1f5bedb1a580c30c7f69bf';

/// 退会完了後にログイン画面で完了SnackBarを表示するためのワンショット通知フラグ
///
/// 退会による認証解除直後に GoRouter が `/login` へリダイレクトすると、
/// `SnackBarNavigationObserver` が遷移前の SnackBar を消去するため、
/// 遷移先のログイン画面側で本フラグを消費して安全に通知を表示します。

abstract class _$AccountDeletionNoticeNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
