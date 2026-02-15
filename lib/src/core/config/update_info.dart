import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_info.freezed.dart';
part 'update_info.g.dart';

/// アップデート通知のモデルクラス
@freezed
sealed class UpdateInfo with _$UpdateInfo {
  /// factoryコンストラクタ
  const factory UpdateInfo({
    /// 要求バージョン
    required String requiredVersion,

    /// 有効日（この日時以降のみ有効とする）
    required DateTime enabledAt,

    /// アップデートを後回し可能にするかどうか
    @Default(false) bool canCancel,
  }) = _UpdateInfo;

  /// JSONから作成
  factory UpdateInfo.fromJson(Map<String, dynamic> json) =>
      _$UpdateInfoFromJson(json);
}
