// ignore_for_file: document_ignores

import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/qr_scanner_controller.dart';
import 'package:flutter_sample/src/features/qr_scanner/domain/qr_image_pick_result.dart';
import 'package:flutter_sample/src/features/qr_scanner/domain/qr_scanner_state.dart';
import 'package:flutter_sample/src/features/qr_scanner/presentation/qr_scanner_screen.dart';
import 'package:flutter_sample/src/features/qr_scanner/presentation/widgets/qr_scan_result_sheet.dart';
import 'package:flutter_sample/src/features/qr_scanner/presentation/widgets/qr_scanner_overlay.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// テスト用の MobileScannerPlatform 実装
class FakeMobileScannerPlatform extends MobileScannerPlatform {
  FakeMobileScannerPlatform({
    this.shouldThrowPermissionDenied = false,
    this.shouldThrowUnsupported = false,
    this.shouldThrowOnToggleTorch = false,
    this.shouldThrowOnStop = false,
  });

  final bool shouldThrowPermissionDenied;
  final bool shouldThrowUnsupported;
  final bool shouldThrowOnToggleTorch;
  final bool shouldThrowOnStop;
  final StreamController<BarcodeCapture?> barcodesController =
      StreamController<BarcodeCapture?>.broadcast();

  bool toggleTorchCalled = false;
  bool stopCalled = false;

  @override
  Stream<BarcodeCapture?> get barcodesStream => barcodesController.stream;

  @override
  Stream<TorchState> get torchStateStream => Stream.value(TorchState.off);

  @override
  Stream<double> get zoomScaleStateStream => Stream.value(1);

  @override
  Widget buildCameraView() => const SizedBox(key: Key('mock_camera_view'));

  int startCallCount = 0;

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) {
    startCallCount++;
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
  Future<void> stop() {
    stopCalled = true;
    if (shouldThrowOnStop) {
      return Future.error(
        const MobileScannerException(
          errorCode: MobileScannerErrorCode.controllerUninitialized,
        ),
      );
    }
    return Future.value();
  }

  @override
  Future<void> pause() => Future.value();

  @override
  Future<void> toggleTorch() {
    toggleTorchCalled = true;
    if (shouldThrowOnToggleTorch) {
      return Future.error(
        const MobileScannerException(
          errorCode: MobileScannerErrorCode.controllerUninitialized,
        ),
      );
    }
    return Future.value();
  }

  @override
  Future<void> updateScanWindow(Rect? window) => Future.value();

  @override
  Future<void> dispose() {
    unawaited(barcodesController.close());
    return Future.value();
  }
}

/// テスト用の AppLockService
class FakeAppLockService extends AppLockService {
  @override
  Future<AppLockState> build() async => const AppLockState.disabled();
}

/// テスト用の QrScannerController
class FakeQrScannerController extends QrScannerController {
  FakeQrScannerController({
    QrScannerState initialState = const QrScannerScanning(),
    this.mockScanResult,
    this.mockPickResult = const QrImagePickResult.notFound(),
    this.throwUnsupportedOnPick = false,
    this.pickCompleter,
  }) : _initialState = initialState;

  final QrScannerState _initialState;
  final String? mockScanResult;
  final QrImagePickResult mockPickResult;
  final bool throwUnsupportedOnPick;
  final Completer<QrImagePickResult>? pickCompleter;

  bool toggleTorchCalled = false;
  bool pauseScanningCalled = false;
  bool resumeScanningCalled = false;
  String? lastScannedValue;
  bool pickAndScanImageCalled = false;
  int pickAndScanImageCallCount = 0;

  @override
  QrScannerState build() => _initialState;

  @override
  void toggleTorch() {
    toggleTorchCalled = true;
    state = state.copyWith(isTorchOn: !state.isTorchOn);
  }

  @override
  void pauseScanning() {
    pauseScanningCalled = true;
    state = const QrScannerPaused();
  }

  @override
  void resumeScanning() {
    resumeScanningCalled = true;
    state = const QrScannerScanning();
  }

  @override
  Future<String?> onBarcodeScanned(String rawValue) async {
    lastScannedValue = rawValue;
    return mockScanResult;
  }

  @override
  Future<QrImagePickResult> pickAndScanImage({
    ImagePicker? imagePicker,
    MobileScannerController? scannerController,
    AppLockService? appLockService,
  }) async {
    pickAndScanImageCalled = true;
    pickAndScanImageCallCount++;
    if (throwUnsupportedOnPick) {
      throw const QrScannerUnsupportedPlatformException();
    }
    if (pickCompleter != null) {
      return await pickCompleter!.future;
    }
    return mockPickResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QrScannerScreen', () {
    late FakeMobileScannerPlatform fakePlatform;
    late MobileScannerPlatform originalPlatform;
    late Talker testTalker;

    setUpAll(() {
      originalPlatform = MobileScannerPlatform.instance;
      testTalker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    });

    tearDownAll(() {
      MobileScannerPlatform.instance = originalPlatform;
    });

    setUp(() {
      fakePlatform = FakeMobileScannerPlatform();
      MobileScannerPlatform.instance = fakePlatform;

      // AppSettings のプラットフォームチャネルをモック
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.spencerccf.app_settings/methods'),
            (methodCall) async => null,
          );
      // Clipboard のプラットフォームチャネルをモック
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform,
            (methodCall) async => null,
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.spencerccf.app_settings/methods'),
            null,
          );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Widget createWidget({
      required FakeQrScannerController controller,
      GoRouter? customRouter,
    }) {
      final router =
          customRouter ??
          GoRouter(
            initialLocation: '/qr-scanner',
            routes: [
              GoRoute(
                path: '/qr-scanner',
                builder: (context, state) => const QrScannerScreen(),
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const Scaffold(
                      body: Text('QrScanner History Screen Destination'),
                    ),
                  ),
                ],
              ),
            ],
          );

      return ProviderScope(
        overrides: [
          qrScannerControllerProvider.overrideWith(() => controller),
          appLockServiceProvider.overrideWith(FakeAppLockService.new),
          loggerProvider.overrideWithValue(testTalker),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ja')],
        ),
      );
    }

    testWidgets('初期表示：AppBar、操作ボタン、オーバーレイが正しく描画されること', (tester) async {
      final controller = FakeQrScannerController();

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pumpAndSettle();

      // タイトル表示
      check(find.text('QRコードリーダー')).findsOne();
      // 履歴ボタン
      check(find.byIcon(Icons.history)).findsOne();
      // オーバーレイ案内文
      check(find.text('枠内にQRコードを合わせてください')).findsOne();
      check(find.byType(QrScannerOverlay)).findsOne();
      // 操作バーアイコン（ライトOFF、カメラ切り替え、画像選択）
      check(find.byIcon(Icons.flash_off)).findsOne();
      check(find.byIcon(Icons.cameraswitch)).findsOne();
      check(find.byIcon(Icons.photo_library)).findsOne();
    });

    testWidgets('トーチON状態のとき、flash_on アイコンが表示され、タップでトグルされること', (tester) async {
      final controller = FakeQrScannerController(
        initialState: const QrScannerScanning(isTorchOn: true),
      );

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pumpAndSettle();

      // 初期状態で flash_on アイコンが表示されていること
      check(find.byIcon(Icons.flash_on)).findsOne();

      // タップでトグル
      await tester.tap(find.byIcon(Icons.flash_on));
      await tester.pumpAndSettle();

      check(controller.toggleTorchCalled).isTrue();
      check(fakePlatform.toggleTorchCalled).isTrue();
    });

    testWidgets('カメラ切り替えボタンをタップすると、scannerController の switchCamera が呼ばれること', (
      tester,
    ) async {
      final controller = FakeQrScannerController();

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.cameraswitch));
      await tester.pumpAndSettle();

      check(fakePlatform.stopCalled).isTrue();
      check(find.byIcon(Icons.cameraswitch)).findsOne();
    });

    testWidgets('トーチ切替で例外が発生した場合、エラーが記録され状態が反転しないこと', (tester) async {
      fakePlatform = FakeMobileScannerPlatform(shouldThrowOnToggleTorch: true);
      MobileScannerPlatform.instance = fakePlatform;

      final controller = FakeQrScannerController(
        initialState: const QrScannerScanning(isTorchOn: true),
      );

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.flash_on));
      await tester.pumpAndSettle();

      // エラー発生時は controllerNotifier.toggleTorch は呼ばれない
      check(controller.toggleTorchCalled).isFalse();
      check(fakePlatform.toggleTorchCalled).isTrue();
    });

    testWidgets('カメラ切替で例外が発生した場合、エラーが記録され正常に回復すること', (tester) async {
      fakePlatform = FakeMobileScannerPlatform(shouldThrowOnStop: true);
      MobileScannerPlatform.instance = fakePlatform;

      final controller = FakeQrScannerController();

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.cameraswitch));
      await tester.pumpAndSettle();

      check(fakePlatform.stopCalled).isTrue();
      check(find.byIcon(Icons.cameraswitch)).findsOne();
    });

    testWidgets('バーコード検出時、onBarcodeScanned が呼ばれ、結果シートが表示されること', (tester) async {
      final controller = FakeQrScannerController(
        mockScanResult: 'https://scan-test.com',
      );

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pumpAndSettle();

      // バーコード検出イベントを発火
      fakePlatform.barcodesController.add(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'https://scan-test.com')],
        ),
      );
      await tester.pumpAndSettle();

      check(controller.lastScannedValue).equals('https://scan-test.com');
      // 結果シートが表示されていること
      check(find.byType(QrScanResultSheet)).findsOne();
      check(find.text('https://scan-test.com')).findsOne();
    });

    testWidgets('画像解析中（QrScannerProcessingImage）のとき、ローディングインジケータが表示されること', (
      tester,
    ) async {
      final controller = FakeQrScannerController(
        initialState: const QrScannerProcessingImage(),
      );

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pump();

      check(find.byType(CircularProgressIndicator)).findsOne();
    });

    testWidgets('アルバム画像からQRコードが検出されなかった場合、SnackBar が表示されること', (tester) async {
      final controller = FakeQrScannerController();

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      check(controller.pickAndScanImageCalled).isTrue();
      check(find.text('選択した画像からQRコードを検出できませんでした')).findsOne();
    });

    testWidgets('アルバム画像選択をキャンセルした場合、SnackBar が表示されないこと', (tester) async {
      final controller = FakeQrScannerController(
        mockPickResult: const QrImagePickResult.canceled(),
      );

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      check(controller.pickAndScanImageCalled).isTrue();
      check(find.text('選択した画像からQRコードを検出できませんでした')).findsNothing();
    });

    testWidgets('カメラパーミッション拒否時、エラー案内と設定ボタンが表示されること', (tester) async {
      fakePlatform = FakeMobileScannerPlatform(
        shouldThrowPermissionDenied: true,
      );
      MobileScannerPlatform.instance = fakePlatform;

      final controller = FakeQrScannerController();

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      await tester.pump();

      check(find.byIcon(Icons.videocam_off)).findsOne();
      check(find.text('カメラの権限が必要です')).findsOne();
      check(find.text('設定を開く')).findsOne();

      // 設定ボタンタップ
      await tester.tap(find.text('設定を開く'));
      await tester.pumpAndSettle();
    });

    testWidgets('カメラ非対応（シミュレーター等）時、案内文と「画像から読み取り」ボタンが表示され、タップで画像選択できること', (
      tester,
    ) async {
      fakePlatform = FakeMobileScannerPlatform(shouldThrowUnsupported: true);
      MobileScannerPlatform.instance = fakePlatform;

      final controller = FakeQrScannerController(
        mockPickResult: const QrImagePickResult.success(
          'https://simulator-pick.com',
        ),
      );

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      await tester.pump();

      // 非対応アイコンと案内テキストの確認
      check(find.byIcon(Icons.no_photography)).findsOne();
      check(find.text('カメラを利用できません')).findsOne();
      check(find.text('画像から読み取り')).findsOne();

      // 下部バーのアイコン群は非表示になっていること
      check(find.byIcon(Icons.cameraswitch)).findsNothing();
      check(find.byIcon(Icons.flash_off)).findsNothing();

      // 「画像から読み取り」ボタンタップ
      await tester.tap(find.text('画像から読み取り'));
      await tester.pumpAndSettle();

      check(controller.pickAndScanImageCalled).isTrue();
      check(find.byType(QrScanResultSheet)).findsOne();
      check(find.text('https://simulator-pick.com')).findsOne();
    });

    testWidgets('アルバム画像からQRコードが検出された場合、結果シートが表示されること', (tester) async {
      final controller = FakeQrScannerController(
        mockPickResult: const QrImagePickResult.success(
          'https://picked-qr.com',
        ),
      );

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      check(controller.pickAndScanImageCalled).isTrue();
      check(find.byType(QrScanResultSheet)).findsOne();
      check(find.text('https://picked-qr.com')).findsOne();
    });

    testWidgets('画像選択で QrScannerUnsupportedPlatformException が発生した場合、 '
        'シミュレーター非対応の SnackBar が表示されること', (tester) async {
      final controller = FakeQrScannerController(throwUnsupportedOnPick: true);

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      check(controller.pickAndScanImageCalled).isTrue();
      check(
        find.text(
          'iOSシミュレーター環境では、OSの制約により画像からのQRコード解析がサポートされていません。実機にてお試しください。',
        ),
      ).findsOne();
    });

    testWidgets('画像選択処理の実行中に再度タップされても、多重実行されないこと', (tester) async {
      final completer = Completer<QrImagePickResult>();
      final controller = FakeQrScannerController(pickCompleter: completer);

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pumpAndSettle();

      // 1回目のタップ（処理開始）
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pump();

      check(controller.pickAndScanImageCallCount).equals(1);

      // 処理が完了していない状態で2回目のタップ（無視されること）
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pump();

      check(controller.pickAndScanImageCallCount).equals(1);

      // 処理を完了させる
      completer.complete(const QrImagePickResult.notFound());
      await tester.pumpAndSettle();

      // 完了後はフラグが解除され、再度タップで実行できること
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      check(controller.pickAndScanImageCallCount).equals(2);
    });

    testWidgets('履歴ボタンタップで pauseScanning が呼ばれ、履歴画面へ遷移すること', (tester) async {
      final controller = FakeQrScannerController();

      await tester.pumpWidget(createWidget(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      check(controller.pauseScanningCalled).isTrue();
      check(find.text('QrScanner History Screen Destination')).findsOne();
    });

    testWidgets('履歴画面から戻ったとき、resumeScanning が呼ばれること', (tester) async {
      final controller = FakeQrScannerController();

      final router = GoRouter(
        initialLocation: '/qr-scanner',
        routes: [
          GoRoute(
            path: '/qr-scanner',
            builder: (context, state) => const QrScannerScreen(),
            routes: [
              GoRoute(
                path: 'history',
                builder: (context, state) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back'),
                  ),
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        createWidget(controller: controller, customRouter: router),
      );
      await tester.pumpAndSettle();

      // 履歴画面へ遷移
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      check(controller.pauseScanningCalled).isTrue();

      // 戻る
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      check(controller.resumeScanningCalled).isTrue();
    });
  });
}
