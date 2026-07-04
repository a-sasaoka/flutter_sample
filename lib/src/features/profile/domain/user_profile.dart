import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// ユーザーのプロフィールデータを表すドメインモデル
@freezed
sealed class UserProfile with _$UserProfile {
  /// ファクトリコンストラクタ
  const factory UserProfile({
    /// 氏名
    required String name,

    /// メールアドレス
    required String email,

    /// 表示名（任意入力のためデフォルト空文字）
    @Default('') String displayName,

    /// 電話番号（任意入力のためデフォルト空文字）
    @Default('') String phone,
  }) = _UserProfile;

  /// JSONからUserProfileオブジェクトを生成するファクトリコンストラクタ
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
