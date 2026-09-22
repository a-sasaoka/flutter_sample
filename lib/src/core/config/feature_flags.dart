import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_flags.freezed.dart';

/// アプリの遠隔機能制御（フィーチャーフラグ・動的バナー）を管理するデータモデル
@freezed
sealed class FeatureFlags with _$FeatureFlags {
  /// factoryコンストラクタ
  const factory FeatureFlags({
    /// QRコードスキャナー機能の利用可否
    @Default(true) bool isQrScannerEnabled,

    /// 動的お知らせバナーのメッセージ（空文字の場合は非表示）
    @Default('') String announcementMessage,
  }) = _FeatureFlags;
}
