import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_payload.freezed.dart';
part 'notification_payload.g.dart';

/// path, route, deep_link の候補から有効な遷移パスを抽出するヘルパー
Object? _readPath(Map<dynamic, dynamic> json, String key) {
  String? checkKey(String k) {
    final val = (json[k] as String?)?.trim();
    return (val != null && val.isNotEmpty) ? val : null;
  }

  return checkKey('path') ?? checkKey('route') ?? checkKey('deep_link');
}

/// 🔔 Push通知およびローカル通知のペイロード（データ）を表すFreezedモデル
@freezed
sealed class NotificationPayload with _$NotificationPayload {
  /// コンストラクタ
  const factory NotificationPayload({
    /// 遷移先の画面パス（例: `/chat`, `/memos/detail?id=123`）
    // ignore: invalid_annotation_target
    @JsonKey(readValue: _readPath) String? path,

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
    final payload = NotificationPayload.fromJson(map);
    return payload.copyWith(
      title: title ?? payload.title,
      body: body ?? payload.body,
      data: Map<String, dynamic>.from(map),
    );
  }

  /// 画面遷移が可能なパスが含まれているかどうか
  bool get isNavigable => path != null && path!.trim().isNotEmpty;
}
