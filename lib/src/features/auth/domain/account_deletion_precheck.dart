import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_deletion_precheck.freezed.dart';

/// 再認証に利用可能な認証手段
enum ReauthMethod {
  /// メールアドレスとパスワードによる再認証
  password,

  /// Googleアカウントによる再認証
  google,
}

/// 退会実行前の再認証要件チェック結果
@freezed
sealed class AccountDeletionPrecheck with _$AccountDeletionPrecheck {
  /// コンストラクタ
  const factory AccountDeletionPrecheck({
    /// 破壊的削除を始める前に再認証モーダルを表示すべきか
    required bool requiresReauthentication,

    /// 利用可能な再認証手段
    required Set<ReauthMethod> availableMethods,

    /// 現在のユーザーのメールアドレス（パスワード再認証モーダル表示用）
    String? email,
  }) = _AccountDeletionPrecheck;
}
