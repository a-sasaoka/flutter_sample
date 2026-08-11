import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';

part 'location_state.freezed.dart';

/// 🗺️ 位置情報およびパーミッションの状態を表す Sealed class
@freezed
sealed class LocationState with _$LocationState {
  /// 初期状態
  const factory LocationState.initial() = LocationStateInitial;

  /// 位置情報取得中
  const factory LocationState.loading() = LocationStateLoading;

  /// 取得成功
  const factory LocationState.success(Position position) = LocationStateSuccess;

  /// パーミッション拒否 (1回目)
  const factory LocationState.permissionDenied() =
      LocationStatePermissionDenied;

  /// パーミッション永久拒否 (端末設定画面誘導が必要)
  const factory LocationState.permissionDeniedForever() =
      LocationStatePermissionDeniedForever;

  /// 位置情報サービス (GPS) 自体が無効
  const factory LocationState.serviceDisabled() = LocationStateServiceDisabled;

  /// エラー発生
  const factory LocationState.error(String message) = LocationStateError;
}
