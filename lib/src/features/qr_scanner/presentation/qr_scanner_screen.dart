import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/app/router/app_router.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/qr_scanner_controller.dart';
import 'package:flutter_sample/src/features/qr_scanner/domain/qr_image_pick_result.dart';
import 'package:flutter_sample/src/features/qr_scanner/domain/qr_scanner_state.dart';
import 'package:flutter_sample/src/features/qr_scanner/presentation/widgets/qr_scan_result_sheet.dart';
import 'package:flutter_sample/src/features/qr_scanner/presentation/widgets/qr_scanner_overlay.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QRコードスキャナー画面
class QrScannerScreen extends HookConsumerWidget {
  /// コンストラクタ
  const QrScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scannerState = ref.watch(qrScannerControllerProvider);
    final controllerNotifier = ref.read(qrScannerControllerProvider.notifier);

    // MobileScannerControllerのライフサイクル管理
    final scannerController = useMemoized(
      () => MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
      ),
    );
    useEffect(() => scannerController.dispose, [scannerController]);

    Future<void> handlePickImage() async {
      try {
        final result = await controllerNotifier.pickAndScanImage(
          scannerController: scannerController,
        );
        if (!context.mounted) {
          return;
        }

        switch (result) {
          case QrImagePickSuccess(:final rawValue):
            await QrScanResultSheet.show(context, rawValue);
          case QrImagePickNotFound():
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.qrScannerInvalidImage)));
          case QrImagePickCanceled():
            // ユーザーによるキャンセルのため通知は表示しない
            break;
        }
      } on QrScannerUnsupportedPlatformException catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.qrScannerUnsupportedSimulator)),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.qrScannerTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.qrScannerHistoryTitle,
            onPressed: () async {
              controllerNotifier.pauseScanning();
              await const QrScannerHistoryRoute().push<void>(context);
              controllerNotifier.resumeScanning();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // カメラプレビュー
          MobileScanner(
            controller: scannerController,
            errorBuilder: (context, error) {
              return _CameraErrorView(
                error: error,
                onOpenSettings: () => ref
                    .read(appLockServiceProvider.notifier)
                    .runWithLockSuppression(AppSettings.openAppSettings),
                onPickImage: handlePickImage,
              );
            },
            onDetect: (capture) async {
              final barcode = capture.barcodes.firstOrNull;
              final rawValue = barcode?.rawValue;
              if (rawValue != null) {
                final result = await controllerNotifier.onBarcodeScanned(
                  rawValue,
                );
                if (result != null && context.mounted) {
                  await QrScanResultSheet.show(context, result);
                }
              }
            },
          ),
          // スキャン枠オーバーレイ（エラー時は非表示）
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: scannerController,
            builder: (context, value, _) {
              if (value.error != null) {
                return const SizedBox.shrink();
              }
              return const QrScannerOverlay();
            },
          ),
          // 下部操作ボタンバー（エラー時は非表示）
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: scannerController,
            builder: (context, value, _) {
              if (value.error != null) {
                return const SizedBox.shrink();
              }
              return Positioned(
                left: 0,
                right: 0,
                bottom: 32,
                child: _ScannerControlBar(
                  isTorchOn: scannerState.isTorchOn,
                  onToggleTorch: () async {
                    try {
                      await scannerController.toggleTorch();
                      controllerNotifier.toggleTorch();
                    } on Exception catch (e, st) {
                      ref
                          .read(loggerProvider)
                          .error('Failed to toggle torch: $e\n$st');
                    }
                  },
                  onSwitchCamera: () async {
                    try {
                      await scannerController.switchCamera();
                    } on Exception catch (e, st) {
                      ref
                          .read(loggerProvider)
                          .error('Failed to switch camera: $e\n$st');
                    }
                  },
                  onPickImage: handlePickImage,
                ),
              );
            },
          ),
          // 画像解析中のローディング表示
          if (scannerState is QrScannerProcessingImage)
            const ColoredBox(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _ScannerControlBar extends StatelessWidget {
  const _ScannerControlBar({
    required this.isTorchOn,
    required this.onToggleTorch,
    required this.onSwitchCamera,
    required this.onPickImage,
  });

  final bool isTorchOn;
  final VoidCallback onToggleTorch;
  final VoidCallback onSwitchCamera;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton.filledTonal(
          onPressed: onToggleTorch,
          icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off),
        ),
        IconButton.filledTonal(
          onPressed: onSwitchCamera,
          icon: const Icon(Icons.cameraswitch),
        ),
        IconButton.filledTonal(
          onPressed: onPickImage,
          icon: const Icon(Icons.photo_library),
        ),
      ],
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({
    required this.error,
    required this.onOpenSettings,
    required this.onPickImage,
  });

  final MobileScannerException error;
  final VoidCallback onOpenSettings;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isUnsupported = error.errorCode == MobileScannerErrorCode.unsupported;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnsupported ? Icons.no_photography : Icons.videocam_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isUnsupported
                  ? l10n.qrScannerUnsupportedTitle
                  : l10n.qrScannerPermissionDeniedTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isUnsupported
                  ? l10n.qrScannerUnsupportedMessage
                  : l10n.qrScannerPermissionDeniedMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isUnsupported)
              FilledButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.photo_library),
                label: Text(l10n.qrScannerPickImage),
              )
            else
              FilledButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings),
                label: Text(l10n.qrScannerOpenSettings),
              ),
          ],
        ),
      ),
    );
  }
}
