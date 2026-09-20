import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/qr_scanner_controller.dart';
import 'package:flutter_sample/src/features/qr_scanner/data/qr_scan_histories_dao.dart';
import 'package:flutter_sample/src/features/qr_scanner/domain/qr_image_pick_result.dart';
import 'package:flutter_sample/src/features/qr_scanner/domain/qr_scanner_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockQrScanHistoriesDao extends Mock implements QrScanHistoriesDao {}

class MockImagePicker extends Mock implements ImagePicker {}

class MockImagePickerPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements ImagePickerPlatform {}

class MockMobileScannerController extends Mock
    implements MobileScannerController {}

class MockAppLockService extends Mock implements AppLockService {}

class FakeAppLockService extends AppLockService {
  @override
  Future<AppLockState> build() async => const AppLockState.disabled();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const ImagePickerOptions());
  });

  group('QrScannerController', () {
    late MockQrScanHistoriesDao mockDao;
    late ProviderContainer container;

    setUp(() {
      mockDao = MockQrScanHistoriesDao();
      container = ProviderContainer(
        overrides: [
          qrScanHistoriesDaoProvider.overrideWithValue(mockDao),
          loggerProvider.overrideWithValue(Talker()),
          appLockServiceProvider.overrideWith(FakeAppLockService.new),
        ],
      );
      when(() => mockDao.upsertHistory(any())).thenAnswer((_) async {});
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態は scanning かつ isTorchOn=false であること', () {
      final state = container.read(qrScannerControllerProvider);
      check(state).equals(const QrScannerState.scanning());
      check(
        container.read(qrScannerControllerProvider.notifier).isScanning,
      ).equals(true);
    });

    test('pauseScanning / resumeScanning でスキャン状態が正しく切り替わること', () {
      final notifier = container.read(qrScannerControllerProvider.notifier)
        ..pauseScanning();
      check(notifier.isScanning).equals(false);
      check(
        container.read(qrScannerControllerProvider),
      ).equals(const QrScannerState.paused());

      notifier.resumeScanning();
      check(notifier.isScanning).equals(true);
      check(
        container.read(qrScannerControllerProvider),
      ).equals(const QrScannerState.scanning());
    });

    test('toggleTorch でライトの ON/OFF が切り替わること（各状態に対応）', () async {
      // 1. scanning 状態でのトグル
      final notifier = container.read(qrScannerControllerProvider.notifier)
        ..toggleTorch();
      check(container.read(qrScannerControllerProvider).isTorchOn).equals(true);
      notifier.toggleTorch();
      check(
        container.read(qrScannerControllerProvider).isTorchOn,
      ).equals(false);

      // 2. paused 状態でのトグル
      notifier
        ..pauseScanning()
        ..toggleTorch();
      check(container.read(qrScannerControllerProvider).isTorchOn).equals(true);
      check(
        container.read(qrScannerControllerProvider),
      ).equals(const QrScannerState.paused(isTorchOn: true));

      notifier.toggleTorch();
      check(
        container.read(qrScannerControllerProvider).isTorchOn,
      ).equals(false);
      check(
        container.read(qrScannerControllerProvider),
      ).equals(const QrScannerState.paused());

      // 3. processingImage 状態でのトグル
      notifier.resumeScanning();
      final mockPicker = MockImagePicker();
      final completer = Completer<XFile?>();
      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) => completer.future);

      final future = notifier.pickAndScanImage(
        imagePicker: mockPicker,
        scannerController: MockMobileScannerController(),
      );

      check(
        container.read(qrScannerControllerProvider),
      ).isA<QrScannerProcessingImage>();
      notifier.toggleTorch();
      check(container.read(qrScannerControllerProvider).isTorchOn).equals(true);

      completer.complete(null);
      await future;
    });

    test('onBarcodeScanned: スキャン可能なときは一時停止して保存し値を返すこと', () async {
      final subscription = container.listen(
        qrScannerControllerProvider,
        (_, _) {},
      );
      final notifier = container.read(qrScannerControllerProvider.notifier);

      final result = await notifier.onBarcodeScanned('https://flutter.dev');
      check(result).equals('https://flutter.dev');
      check(notifier.isScanning).equals(false);
      verify(() => mockDao.upsertHistory('https://flutter.dev')).called(1);
      subscription.close();
    });

    test(
      'onBarcodeScanned: すでに一時停止中（isScanning=false）のときはスルーして二重読み取りを防ぐこと',
      () async {
        final notifier = container.read(qrScannerControllerProvider.notifier)
          ..pauseScanning();

        final result = await notifier.onBarcodeScanned('https://flutter.dev');
        check(result).isNull();
        verifyNever(() => mockDao.upsertHistory(any()));
      },
    );

    test('onBarcodeScanned: 空文字の場合は処理しないこと', () async {
      final notifier = container.read(qrScannerControllerProvider.notifier);

      final result = await notifier.onBarcodeScanned('');
      check(result).isNull();
      verifyNever(() => mockDao.upsertHistory(any()));
    });

    test('pickAndScanImage: 写真選択キャンセル時は null が返りスキャンが再開されること', () async {
      final subscription = container.listen(
        qrScannerControllerProvider,
        (_, _) {},
      );
      final mockPicker = MockImagePicker();
      final mockController = MockMobileScannerController();
      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => null);

      final notifier = container.read(qrScannerControllerProvider.notifier);
      final result = await notifier.pickAndScanImage(
        imagePicker: mockPicker,
        scannerController: mockController,
      );

      check(result).equals(const QrImagePickResult.canceled());
      check(notifier.isScanning).equals(true);
      subscription.close();
    });

    test('pickAndScanImage: QRコードが見つかった場合は保存されスキャン一時停止になること', () async {
      final subscription = container.listen(
        qrScannerControllerProvider,
        (_, _) {},
      );
      final mockPicker = MockImagePicker();
      final mockController = MockMobileScannerController();
      final xFile = XFile('/path/to/qr.png');

      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => xFile);
      when(() => mockController.analyzeImage(xFile.path)).thenAnswer(
        (_) async => const BarcodeCapture(
          barcodes: [
            Barcode(
              format: BarcodeFormat.qrCode,
              rawValue: 'https://example.com',
            ),
          ],
        ),
      );

      final notifier = container.read(qrScannerControllerProvider.notifier);
      final result = await notifier.pickAndScanImage(
        imagePicker: mockPicker,
        scannerController: mockController,
      );

      check(
        result,
      ).equals(const QrImagePickResult.success('https://example.com'));
      check(notifier.isScanning).equals(false);
      verify(() => mockDao.upsertHistory('https://example.com')).called(1);
      subscription.close();
    });

    test(
      'pickAndScanImage: QRコードの値が空文字の場合は notFound となりスキャンが再開されること',
      () async {
        final subscription = container.listen(
          qrScannerControllerProvider,
          (_, _) {},
        );
        final mockPicker = MockImagePicker();
        final mockController = MockMobileScannerController();
        final xFile = XFile('/path/to/qr.png');

        when(
          () => mockPicker.pickImage(source: ImageSource.gallery),
        ).thenAnswer((_) async => xFile);
        when(() => mockController.analyzeImage(xFile.path)).thenAnswer(
          (_) async => const BarcodeCapture(
            barcodes: [Barcode(format: BarcodeFormat.qrCode, rawValue: '')],
          ),
        );

        final notifier = container.read(qrScannerControllerProvider.notifier);
        final result = await notifier.pickAndScanImage(
          imagePicker: mockPicker,
          scannerController: mockController,
        );

        check(result).equals(const QrImagePickResult.notFound());
        check(notifier.isScanning).equals(true);
        verifyNever(() => mockDao.upsertHistory(any()));
        subscription.close();
      },
    );

    test('pickAndScanImage: UnsupportedError 発生時はログ記録して '
        'QrScannerUnsupportedPlatformException が投げられること', () async {
      final subscription = container.listen(
        qrScannerControllerProvider,
        (_, _) {},
      );
      final mockPicker = MockImagePicker();
      final mockController = MockMobileScannerController();
      final xFile = XFile('/path/to/qr.png');

      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => xFile);
      when(
        () => mockController.analyzeImage(xFile.path),
      ).thenThrow(UnsupportedError('Not supported on simulator.'));

      final notifier = container.read(qrScannerControllerProvider.notifier);
      await check(
        notifier.pickAndScanImage(
          imagePicker: mockPicker,
          scannerController: mockController,
        ),
      ).throws<QrScannerUnsupportedPlatformException>();

      check(notifier.isScanning).equals(true);
      subscription.close();
    });

    test('QrScannerUnsupportedPlatformException: toString が正しく動作すること', () {
      const defaultException = QrScannerUnsupportedPlatformException();
      check(defaultException.toString()).contains('Platform not supported');

      const customException = QrScannerUnsupportedPlatformException(
        'Custom error',
      );
      check(customException.toString()).equals('Custom error');
    });

    test('onBarcodeScanned: 履歴保存で例外が発生した場合もクラッシュせずQRコード文字列を返すこと', () async {
      final subscription = container.listen(
        qrScannerControllerProvider,
        (_, _) {},
      );
      when(() => mockDao.upsertHistory(any())).thenThrow(Exception('DB Error'));
      final notifier = container.read(qrScannerControllerProvider.notifier);

      final result = await notifier.onBarcodeScanned('https://flutter.dev');
      check(result).equals('https://flutter.dev');
      check(notifier.isScanning).equals(false);
      subscription.close();
    });

    test('pickAndScanImage: 引数を指定しない場合はデフォルトのインスタンスが使用されること', () async {
      final subscription = container.listen(
        qrScannerControllerProvider,
        (_, _) {},
      );
      final originalPlatform = ImagePickerPlatform.instance;
      final mockPlatform = MockImagePickerPlatform();
      ImagePickerPlatform.instance = mockPlatform;
      when(
        () => mockPlatform.getImageFromSource(
          source: ImageSource.gallery,
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => null);

      final notifier = container.read(qrScannerControllerProvider.notifier);
      final result = await notifier.pickAndScanImage();

      check(result).equals(const QrImagePickResult.canceled());
      check(notifier.isScanning).equals(true);

      ImagePickerPlatform.instance = originalPlatform;
      subscription.close();
    });

    test('pickAndScanImage: バーコードが検出されない（nullまたは空） '
        '場合は null が返りスキャンが再開されること', () async {
      final subscription = container.listen(
        qrScannerControllerProvider,
        (_, _) {},
      );
      final mockPicker = MockImagePicker();
      final mockController = MockMobileScannerController();
      final xFile = XFile('/path/to/qr.png');

      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => xFile);

      final notifier = container.read(qrScannerControllerProvider.notifier);

      // 1. analyzeImage が null を返した場合
      when(
        () => mockController.analyzeImage(xFile.path),
      ).thenAnswer((_) async => null);
      var result = await notifier.pickAndScanImage(
        imagePicker: mockPicker,
        scannerController: mockController,
      );
      check(result).equals(const QrImagePickResult.notFound());
      check(notifier.isScanning).equals(true);

      // 2. analyzeImage の barcodes が空の場合
      when(
        () => mockController.analyzeImage(xFile.path),
      ).thenAnswer((_) async => const BarcodeCapture());
      result = await notifier.pickAndScanImage(
        imagePicker: mockPicker,
        scannerController: mockController,
      );
      check(result).equals(const QrImagePickResult.notFound());
      check(notifier.isScanning).equals(true);
      subscription.close();
    });

    test('pickAndScanImage: QRコード以外またはrawValueがnullの '
        '場合は null が返りスキャンが再開されること', () async {
      final subscription = container.listen(
        qrScannerControllerProvider,
        (_, _) {},
      );
      final mockPicker = MockImagePicker();
      final mockController = MockMobileScannerController();
      final xFile = XFile('/path/to/qr.png');

      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => xFile);
      when(() => mockController.analyzeImage(xFile.path)).thenAnswer(
        (_) async => const BarcodeCapture(
          barcodes: [
            Barcode(format: BarcodeFormat.code128, rawValue: '12345'),
            Barcode(format: BarcodeFormat.qrCode),
          ],
        ),
      );

      final notifier = container.read(qrScannerControllerProvider.notifier);
      final result = await notifier.pickAndScanImage(
        imagePicker: mockPicker,
        scannerController: mockController,
      );

      check(result).equals(const QrImagePickResult.notFound());
      check(notifier.isScanning).equals(true);
      subscription.close();
    });

    test('pickAndScanImage: QRコード検出時に履歴保存で例外が発生した場合もクラッシュせず値を返すこと', () async {
      final subscription = container.listen(
        qrScannerControllerProvider,
        (_, _) {},
      );
      when(() => mockDao.upsertHistory(any())).thenThrow(Exception('DB Error'));
      final mockPicker = MockImagePicker();
      final mockController = MockMobileScannerController();
      final xFile = XFile('/path/to/qr.png');

      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => xFile);
      when(() => mockController.analyzeImage(xFile.path)).thenAnswer(
        (_) async => const BarcodeCapture(
          barcodes: [
            Barcode(
              format: BarcodeFormat.qrCode,
              rawValue: 'https://example.com',
            ),
          ],
        ),
      );

      final notifier = container.read(qrScannerControllerProvider.notifier);
      final result = await notifier.pickAndScanImage(
        imagePicker: mockPicker,
        scannerController: mockController,
      );

      check(
        result,
      ).equals(const QrImagePickResult.success('https://example.com'));
      check(notifier.isScanning).equals(false);
      subscription.close();
    });

    test('pickAndScanImage: 画像解析中に例外が発生した場合は finally でスキャンが再開されること', () async {
      final subscription = container.listen(
        qrScannerControllerProvider,
        (_, _) {},
      );
      final mockPicker = MockImagePicker();
      final mockController = MockMobileScannerController();
      final xFile = XFile('/path/to/qr.png');

      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => xFile);
      when(
        () => mockController.analyzeImage(xFile.path),
      ).thenThrow(Exception('Analyze failed'));

      final notifier = container.read(qrScannerControllerProvider.notifier);
      await check(
        notifier.pickAndScanImage(
          imagePicker: mockPicker,
          scannerController: mockController,
        ),
      ).throws<Exception>();

      check(
        container.read(qrScannerControllerProvider),
      ).isA<QrScannerScanning>();
      subscription.close();
    });

    test(
      'pickAndScanImage: appLockService 指定時に runWithLockSuppression を呼ぶこと',
      () async {
        final subscription = container.listen(
          qrScannerControllerProvider,
          (_, _) {},
        );
        final mockPicker = MockImagePicker();
        final mockController = MockMobileScannerController();
        final mockLockService = MockAppLockService();

        when(
          () => mockLockService.runWithLockSuppression<XFile?>(any()),
        ).thenAnswer((invocation) async {
          final action =
              invocation.positionalArguments[0] as Future<XFile?> Function();
          return await action();
        });
        when(
          () => mockPicker.pickImage(source: ImageSource.gallery),
        ).thenAnswer((_) async => null);

        final notifier = container.read(qrScannerControllerProvider.notifier);
        final result = await notifier.pickAndScanImage(
          imagePicker: mockPicker,
          scannerController: mockController,
          appLockService: mockLockService,
        );

        check(result).equals(const QrImagePickResult.canceled());
        verify(
          () => mockLockService.runWithLockSuppression<XFile?>(any()),
        ).called(1);
        verify(
          () => mockPicker.pickImage(source: ImageSource.gallery),
        ).called(1);
        subscription.close();
      },
    );
  });
}
