import 'package:freezed_annotation/freezed_annotation.dart';

part 'qr_image_pick_result.freezed.dart';

/// 画像選択によるQRコード解析の結果を表す sealed クラス
@freezed
sealed class QrImagePickResult with _$QrImagePickResult {
  /// QRコードが正常に検出された場合
  const factory QrImagePickResult.success(String rawValue) = QrImagePickSuccess;

  /// ユーザーが画像選択をキャンセルした場合
  const factory QrImagePickResult.canceled() = QrImagePickCanceled;

  /// 画像からQRコードが検出されなかった場合
  const factory QrImagePickResult.notFound() = QrImagePickNotFound;
}
