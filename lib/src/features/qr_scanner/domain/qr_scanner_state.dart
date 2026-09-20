import 'package:freezed_annotation/freezed_annotation.dart';

part 'qr_scanner_state.freezed.dart';

/// QRコードスキャナーの状態を表す sealed クラス
@freezed
sealed class QrScannerState with _$QrScannerState {
  /// カメラでリアルタイムスキャン中
  const factory QrScannerState.scanning({@Default(false) bool isTorchOn}) =
      QrScannerScanning;

  /// 写真アルバムから選んだ画像を解析中
  const factory QrScannerState.processingImage({
    @Default(false) bool isTorchOn,
  }) = QrScannerProcessingImage;

  /// スキャン一時停止中（結果シート表示中・画面非表示時など）
  const factory QrScannerState.paused({@Default(false) bool isTorchOn}) =
      QrScannerPaused;
}
