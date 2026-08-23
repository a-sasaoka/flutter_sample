import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_sample/src/features/notification/domain/notification_payload.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_state.freezed.dart';

/// 🔔 通知の状態を表す sealed クラス
@freezed
sealed class NotificationState with _$NotificationState {
  /// 初期化中（FCMトークン取得中）
  const factory NotificationState.loading() = NotificationStateLoading;

  /// 読み込み完了・利用可能状態
  const factory NotificationState.data({
    /// 取得した FCM トークン
    String? fcmToken,

    /// 通知権限のステータス
    AuthorizationStatus? authorizationStatus,

    /// 最後に受信・タップされた通知ペイロード
    NotificationPayload? latestPayload,
  }) = NotificationStateData;

  /// エラー発生状態
  const factory NotificationState.error({
    required String message,
  }) = NotificationStateError;
}
