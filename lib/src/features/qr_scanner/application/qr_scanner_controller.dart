import 'package:flutter/services.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/qr_scanner/data/qr_scan_histories_dao.dart';
import 'package:flutter_sample/src/features/qr_scanner/domain/qr_image_pick_result.dart';
import 'package:flutter_sample/src/features/qr_scanner/domain/qr_scanner_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'qr_scanner_controller.g.dart';

/// 画像解析機能がプラットフォーム（iOSシミュレーター等）でサポートされていない場合の例外
class QrScannerUnsupportedPlatformException implements Exception {
  /// コンストラクタ
  const QrScannerUnsupportedPlatformException([this.message]);

  /// エラーメッセージ
  final String? message;

  @override
  String toString() =>
      message ??
      'QrScannerUnsupportedPlatformException: Platform not supported';
}

/// QRコードリーダーのロジックと状態を管理するコントローラー
@riverpod
class QrScannerController extends _$QrScannerController {
  @override
  QrScannerState build() => const QrScannerState.scanning();

  /// 現在スキャンを受け付けているかどうか
  bool get isScanning => switch (state) {
    QrScannerScanning() => true,
    QrScannerProcessingImage() || QrScannerPaused() => false,
  };

  /// スキャンを一時停止します
  void pauseScanning() {
    state = QrScannerState.paused(isTorchOn: state.isTorchOn);
  }

  /// スキャンを再開します
  void resumeScanning() {
    state = QrScannerState.scanning(isTorchOn: state.isTorchOn);
  }

  /// ライト（トーチ）の点灯状態を切り替えます
  void toggleTorch() {
    final nextTorch = !state.isTorchOn;
    state = switch (state) {
      QrScannerScanning() => QrScannerState.scanning(isTorchOn: nextTorch),
      QrScannerProcessingImage() => QrScannerState.processingImage(
        isTorchOn: nextTorch,
      ),
      QrScannerPaused() => QrScannerState.paused(isTorchOn: nextTorch),
    };
  }

  /// カメラからQRコードが検出されたときの処理
  ///
  /// 一時停止中（[isScanning] が false）の場合は無視します。
  /// スキャン成功時は振動させ、データベースへ保存した上で検出された文字列を返します。
  Future<String?> onBarcodeScanned(String rawValue) async {
    if (!isScanning || rawValue.isEmpty) {
      return null;
    }

    // 二重読み取りを防ぐために一時停止
    pauseScanning();

    // 触覚フィードバック（ブルッと振動）
    await HapticFeedback.lightImpact();

    // データベースへ保存（同一データは日時更新）
    try {
      await ref.read(qrScanHistoriesDaoProvider).upsertHistory(rawValue);
    } on Exception catch (e, st) {
      ref.read(loggerProvider).error('Failed to save scan history: $e\n$st');
    }

    return rawValue;
  }

  /// 写真アルバムから画像を選択し、QRコードを読み取ります
  Future<QrImagePickResult> pickAndScanImage({
    ImagePicker? imagePicker,
    MobileScannerController? scannerController,
    AppLockService? appLockService,
  }) async {
    final picker = imagePicker ?? ImagePicker();
    final controller = scannerController ?? MobileScannerController();
    final lockService =
        appLockService ??
        ref.read<AppLockService>(appLockServiceProvider.notifier);

    state = QrScannerState.processingImage(isTorchOn: state.isTorchOn);

    try {
      final image = await lockService.runWithLockSuppression(
        () => picker.pickImage(source: ImageSource.gallery),
      );
      if (image == null) {
        resumeScanning();
        return const QrImagePickResult.canceled();
      }

      final barcodes = await controller.analyzeImage(image.path);
      if (barcodes == null || barcodes.barcodes.isEmpty) {
        resumeScanning();
        return const QrImagePickResult.notFound();
      }

      // 最初の有効なQRコード値を取得（空文字は無効とする）
      final rawValue = barcodes.barcodes
          .where(
            (b) =>
                b.format == BarcodeFormat.qrCode &&
                b.rawValue != null &&
                b.rawValue!.isNotEmpty,
          )
          .map((b) => b.rawValue!)
          .firstOrNull;

      if (rawValue != null) {
        await HapticFeedback.lightImpact();
        try {
          await ref.read(qrScanHistoriesDaoProvider).upsertHistory(rawValue);
        } on Exception catch (e, st) {
          ref
              .read(loggerProvider)
              .error('Failed to save scan history: $e\n$st');
        }
        pauseScanning();
        return QrImagePickResult.success(rawValue);
      }

      resumeScanning();
      return const QrImagePickResult.notFound();
      // ignore: avoid_catching_errors, mobile_scanner throws UnsupportedError on iOS Simulator
    } on UnsupportedError catch (e, st) {
      ref
          .read(loggerProvider)
          .warning('Analyzing image is unsupported on this platform: $e\n$st');
      throw const QrScannerUnsupportedPlatformException();
    } finally {
      if (state is QrScannerProcessingImage) {
        resumeScanning();
      }
    }
  }
}
