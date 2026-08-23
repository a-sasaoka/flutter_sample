import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_payload.freezed.dart';
part 'notification_payload.g.dart';

/// 🔔 Push通知およびローカル通知のペイロード（データ）を表すFreezedモデル
@freezed
sealed class NotificationPayload with _$NotificationPayload {
  /// コンストラクタ
  const factory NotificationPayload({
    /// 遷移先の画面パス（例: `/chat`, `/memos/detail?id=123`）
    String? path,

    /// 通知のタイトル
    String? title,

    /// 通知の本文
    String? body,

    /// その他のカスタムデータ
    @Default({}) Map<String, dynamic> data,
  }) = _NotificationPayload;

  const NotificationPayload._();

  /// JSON（Map）から [NotificationPayload] を自動パース生成
  factory NotificationPayload.fromJson(Map<String, dynamic> json) =>
      _$NotificationPayloadFromJson(json);

  /// Firebase RemoteMessage.data などの Map から生成するファクトリ
  factory NotificationPayload.fromMap(
    Map<String, dynamic> map, {
    String? title,
    String? body,
  }) {
    final path =
        map['path'] as String? ??
        map['route'] as String? ??
        map['deep_link'] as String?;

    return NotificationPayload(
      path: path,
      title: title ?? map['title'] as String?,
      body: body ?? map['body'] as String?,
      data: Map<String, dynamic>.from(map),
    );
  }

  /// 画面遷移が可能なパスが含まれているかどうか
  bool get isNavigable => path != null && path!.trim().isNotEmpty;
}
