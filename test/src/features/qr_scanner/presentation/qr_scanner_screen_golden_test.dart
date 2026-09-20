import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/qr_scanner_controller.dart';
import 'package:flutter_sample/src/features/qr_scanner/domain/qr_scanner_state.dart';
import 'package:flutter_sample/src/features/qr_scanner/presentation/qr_scanner_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../golden_test_helper.dart';

class GoldenFakeMobileScannerPlatform extends MobileScannerPlatform {
  GoldenFakeMobileScannerPlatform({
    this.shouldThrowPermissionDenied = false,
    this.shouldThrowUnsupported = false,
  });

  final bool shouldThrowPermissionDenied;
  final bool shouldThrowUnsupported;

  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream => Stream.value(TorchState.off);

  @override
  Stream<double> get zoomScaleStateStream => Stream.value(1);

  @override
  Widget buildCameraView() => Container(color: Colors.black87);

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) {
    if (shouldThrowPermissionDenied) {
      return Future.error(
        const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        ),
      );
    }
    if (shouldThrowUnsupported) {
      return Future.error(
        const MobileScannerException(
          errorCode: MobileScannerErrorCode.unsupported,
        ),
      );
    }
    return Future.value(
      const MobileScannerViewAttributes(
        cameraDirection: CameraFacing.back,
        currentTorchMode: TorchState.off,
        size: Size(390, 844),
        numberOfCameras: 2,
        initialDeviceOrientation: DeviceOrientation.portraitUp,
      ),
    );
  }

  @override
  Future<void> stop() => Future.value();

  @override
  Future<void> pause() => Future.value();

  @override
  Future<void> toggleTorch() => Future.value();

  @override
  Future<void> updateScanWindow(Rect? window) => Future.value();

  @override
  Future<void> dispose() => Future.value();
}

class GoldenFakeQrScannerController extends QrScannerController {
  GoldenFakeQrScannerController({
    QrScannerState initialState = const QrScannerScanning(),
  }) : _initialState = initialState;

  final QrScannerState _initialState;

  @override
  QrScannerState build() => _initialState;
}

void main() {
  group('QrScannerScreen Golden Tests', () {
    Widget buildScannerForGolden({
      required ThemeMode themeMode,
      bool permissionDenied = false,
      bool unsupported = false,
    }) {
      MobileScannerPlatform.instance = GoldenFakeMobileScannerPlatform(
        shouldThrowPermissionDenied: permissionDenied,
        shouldThrowUnsupported: unsupported,
      );

      return ProviderScope(
        overrides: [
          qrScannerControllerProvider.overrideWith(
            GoldenFakeQrScannerController.new,
          ),
        ],
        child: buildGoldenTestApp(
          home: const QrScannerScreen(),
          themeMode: themeMode,
        ),
      );
    }

    // ignore: discarded_futures, testing framework registers tests synchronously
    goldenTest(
      'QrScannerScreen 通常スキャン描画 (ライト/ダーク)',
      fileName: 'qr_scanner_screen_scanning',
      builder: () {
        MobileScannerPlatform.instance = GoldenFakeMobileScannerPlatform();
        return GoldenTestGroup(
          children: [
            GoldenTestScenario(
              name: 'Scanning - Light Mode',
              child: SizedBox(
                width: 390,
                height: 844,
                child: buildScannerForGolden(themeMode: ThemeMode.light),
              ),
            ),
            GoldenTestScenario(
              name: 'Scanning - Dark Mode',
              child: SizedBox(
                width: 390,
                height: 844,
                child: buildScannerForGolden(themeMode: ThemeMode.dark),
              ),
            ),
          ],
        );
      },
    );

    // ignore: discarded_futures, testing framework registers tests synchronously
    goldenTest(
      'QrScannerScreen カメラ権限エラー描画 (ライト/ダーク)',
      fileName: 'qr_scanner_screen_error',
      builder: () {
        MobileScannerPlatform.instance = GoldenFakeMobileScannerPlatform(
          shouldThrowPermissionDenied: true,
        );
        return GoldenTestGroup(
          children: [
            GoldenTestScenario(
              name: 'Permission Error - Light Mode',
              child: SizedBox(
                width: 390,
                height: 844,
                child: buildScannerForGolden(
                  themeMode: ThemeMode.light,
                  permissionDenied: true,
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'Permission Error - Dark Mode',
              child: SizedBox(
                width: 390,
                height: 844,
                child: buildScannerForGolden(
                  themeMode: ThemeMode.dark,
                  permissionDenied: true,
                ),
              ),
            ),
          ],
        );
      },
    );

    // ignore: discarded_futures, testing framework registers tests synchronously
    goldenTest(
      'QrScannerScreen カメラ非対応エラー描画 (シミュレーター等、ライト/ダーク)',
      fileName: 'qr_scanner_screen_unsupported',
      builder: () {
        MobileScannerPlatform.instance = GoldenFakeMobileScannerPlatform(
          shouldThrowUnsupported: true,
        );
        return GoldenTestGroup(
          children: [
            GoldenTestScenario(
              name: 'Unsupported Error - Light Mode',
              child: SizedBox(
                width: 390,
                height: 844,
                child: buildScannerForGolden(
                  themeMode: ThemeMode.light,
                  unsupported: true,
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'Unsupported Error - Dark Mode',
              child: SizedBox(
                width: 390,
                height: 844,
                child: buildScannerForGolden(
                  themeMode: ThemeMode.dark,
                  unsupported: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  });
}
