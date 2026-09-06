import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_sample/src/features/profile/data/image_picker_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

/// Mocking PermissionHandlerPlatform requires direct import of the platform
/// interface.
// ignore: depend_on_referenced_packages
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockPermissionHandlerPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PermissionHandlerPlatform {}

class MockImagePicker extends Mock implements ImagePicker {}

class MockImageCropper extends Mock implements ImageCropper {}

class MockCroppedFile extends Mock implements CroppedFile {}

class MockTalker extends Mock implements Talker {}

class MockAppLockService extends Mock implements AppLockService {}

class FakeAppLockService extends AppLockService {
  @override
  Future<AppLockState> build() async => const AppLockState.disabled();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPermissionHandlerPlatform mockPlatform;
  late MockImagePicker mockPicker;
  late MockImageCropper mockCropper;
  late MockTalker mockTalker;
  late ImagePickerService service;

  setUpAll(() {
    registerFallbackValue(ImageSource.gallery);
    registerFallbackValue(CropAspectRatioPreset.square);
    registerFallbackValue(CropStyle.circle);
  });

  setUp(() {
    mockPlatform = MockPermissionHandlerPlatform();
    PermissionHandlerPlatform.instance = mockPlatform;

    mockPicker = MockImagePicker();
    mockCropper = MockImageCropper();
    mockTalker = MockTalker();

    when(() => mockTalker.debug(any<dynamic>())).thenReturn(null);
    when(() => mockTalker.warning(any<dynamic>())).thenReturn(null);

    service = ImagePickerService(
      picker: mockPicker,
      cropper: mockCropper,
      talker: mockTalker,
    );
  });

  group('ImagePickerService checkAndRequestPermission Tests', () {
    test('checkAndRequestPermission: 既に許可(granted)されている場合は正常終了すること', () async {
      when(
        () => mockPlatform.checkPermissionStatus(Permission.camera),
      ).thenAnswer((_) async => PermissionStatus.granted);

      await check(
        service.checkAndRequestPermission(AvatarPickSource.camera),
      ).completes();

      verify(
        () => mockPlatform.checkPermissionStatus(Permission.camera),
      ).called(1);
    });

    test(
      'checkAndRequestPermission: 制限付き許可(limited)されている場合も正常終了すること',
      () async {
        when(
          () => mockPlatform.checkPermissionStatus(Permission.photos),
        ).thenAnswer((_) async => PermissionStatus.limited);

        await check(
          service.checkAndRequestPermission(AvatarPickSource.gallery),
        ).completes();

        verify(
          () => mockPlatform.checkPermissionStatus(Permission.photos),
        ).called(1);
      },
    );

    test(
      'checkAndRequestPermission: 最初から永久拒否(permanentlyDenied)されている場合は例外を投げること',
      () async {
        when(
          () => mockPlatform.checkPermissionStatus(Permission.camera),
        ).thenAnswer((_) async => PermissionStatus.permanentlyDenied);

        await check(
          service.checkAndRequestPermission(AvatarPickSource.camera),
        ).throws<AvatarPermissionDeniedException>();
      },
    );

    test('checkAndRequestPermission: 未許可でリクエスト後に許可された場合は正常終了すること', () async {
      when(
        () => mockPlatform.checkPermissionStatus(Permission.camera),
      ).thenAnswer((_) async => PermissionStatus.denied);
      when(
        () => mockPlatform.requestPermissions([Permission.camera]),
      ).thenAnswer((_) async => {Permission.camera: PermissionStatus.granted});

      await check(
        service.checkAndRequestPermission(AvatarPickSource.camera),
      ).completes();

      verify(
        () => mockPlatform.requestPermissions([Permission.camera]),
      ).called(1);
    });

    test(
      'checkAndRequestPermission: '
      'リクエスト後に永久拒否された場合は isPermanentlyDenied: true で例外を投げること',
      () async {
        when(
          () => mockPlatform.checkPermissionStatus(Permission.camera),
        ).thenAnswer((_) async => PermissionStatus.denied);
        when(
          () => mockPlatform.requestPermissions([Permission.camera]),
        ).thenAnswer(
          (_) async => {Permission.camera: PermissionStatus.permanentlyDenied},
        );

        await check(
          service.checkAndRequestPermission(AvatarPickSource.camera),
        ).throws<AvatarPermissionDeniedException>();
      },
    );

    test('checkAndRequestPermission: リクエスト後に拒否された場合は例外を投げること', () async {
      when(
        () => mockPlatform.checkPermissionStatus(Permission.photos),
      ).thenAnswer((_) async => PermissionStatus.denied);
      when(
        () => mockPlatform.requestPermissions([Permission.photos]),
      ).thenAnswer((_) async => {Permission.photos: PermissionStatus.denied});

      await check(
        service.checkAndRequestPermission(AvatarPickSource.gallery),
      ).throws<AvatarPermissionDeniedException>();
    });
  });

  group('ImagePickerService openSettings Tests', () {
    test('openSettings: プラットフォームの openAppSettings を呼び出すこと', () async {
      when(() => mockPlatform.openAppSettings()).thenAnswer((_) async => true);

      final result = await service.openSettings();
      check(result).isTrue();
      verify(() => mockPlatform.openAppSettings()).called(1);
    });
  });

  group('ImagePickerService pickAndCropAvatar Tests', () {
    const cropperTitle = 'トリミング';

    test('pickAndCropAvatar: 正常系 - 写真選択と切り抜きが成功してファイルパスが返ること', () async {
      when(
        () => mockPlatform.checkPermissionStatus(Permission.camera),
      ).thenAnswer((_) async => PermissionStatus.granted);

      final xFile = XFile('/tmp/picked.jpg');
      when(
        () => mockPicker.pickImage(
          source: ImageSource.camera,
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
        ),
      ).thenAnswer((_) async => xFile);

      final mockCropped = MockCroppedFile();
      when(() => mockCropped.path).thenReturn('/tmp/cropped.jpg');

      when(
        () => mockCropper.cropImage(
          sourcePath: '/tmp/picked.jpg',
          compressQuality: any(named: 'compressQuality'),
          uiSettings: any(named: 'uiSettings'),
        ),
      ).thenAnswer((_) async => mockCropped);

      final result = await service.pickAndCropAvatar(
        source: AvatarPickSource.camera,
        cropperTitle: cropperTitle,
      );

      check(result).equals('/tmp/cropped.jpg');
      verify(
        () => mockPicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        ),
      ).called(1);
    });

    test('pickAndCropAvatar: 写真選択をキャンセルした場合は null を返すこと', () async {
      when(
        () => mockPlatform.checkPermissionStatus(Permission.photos),
      ).thenAnswer((_) async => PermissionStatus.granted);

      when(
        () => mockPicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
        ),
      ).thenAnswer((_) async => null);

      final result = await service.pickAndCropAvatar(
        source: AvatarPickSource.gallery,
        cropperTitle: cropperTitle,
      );

      check(result).isNull();
      verifyNever(
        () => mockCropper.cropImage(
          sourcePath: any(named: 'sourcePath'),
          compressQuality: any(named: 'compressQuality'),
          uiSettings: any(named: 'uiSettings'),
        ),
      );
    });

    test('pickAndCropAvatar: 切り抜きをキャンセルした場合は null を返すこと', () async {
      when(
        () => mockPlatform.checkPermissionStatus(Permission.photos),
      ).thenAnswer((_) async => PermissionStatus.granted);

      final xFile = XFile('/tmp/picked.jpg');
      when(
        () => mockPicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
        ),
      ).thenAnswer((_) async => xFile);

      when(
        () => mockCropper.cropImage(
          sourcePath: '/tmp/picked.jpg',
          compressQuality: any(named: 'compressQuality'),
          uiSettings: any(named: 'uiSettings'),
        ),
      ).thenAnswer((_) async => null);

      final result = await service.pickAndCropAvatar(
        source: AvatarPickSource.gallery,
        cropperTitle: cropperTitle,
      );

      check(result).isNull();
    });

    test(
      'pickAndCropAvatar: appLockService が設定されている場合は '
      'runWithLockSuppression を通して実行されること',
      () async {
        final mockAppLockService = MockAppLockService();
        final serviceWithLock = ImagePickerService(
          picker: mockPicker,
          cropper: mockCropper,
          talker: mockTalker,
          appLockService: mockAppLockService,
        );

        when(
          () => mockPlatform.checkPermissionStatus(Permission.photos),
        ).thenAnswer((_) async => PermissionStatus.granted);
        when(
          () => mockPicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          ),
        ).thenAnswer((_) async => XFile('/path/to/picked.jpg'));

        final mockCropped = MockCroppedFile();
        when(() => mockCropped.path).thenReturn('/path/to/cropped.jpg');
        when(
          () => mockCropper.cropImage(
            sourcePath: '/path/to/picked.jpg',
            compressQuality: 85,
            uiSettings: any(named: 'uiSettings'),
          ),
        ).thenAnswer((_) async => mockCropped);

        when(
          () => mockAppLockService.runWithLockSuppression<String?>(any()),
        ).thenAnswer((invocation) async {
          final action =
              invocation.positionalArguments[0] as Future<String?> Function();
          return action();
        });

        final result = await serviceWithLock.pickAndCropAvatar(
          source: AvatarPickSource.gallery,
          cropperTitle: cropperTitle,
        );

        check(result).equals('/path/to/cropped.jpg');
        verify(
          () => mockAppLockService.runWithLockSuppression<String?>(any()),
        ).called(1);
      },
    );
  });

  group('AvatarPermissionDeniedException Tests', () {
    test('toString: 正しい文字列表現を返すこと', () {
      const exception = AvatarPermissionDeniedException(
        permission: Permission.camera,
        isPermanentlyDenied: true,
      );
      check(exception.toString()).contains('permanently: true');
    });
  });

  group('ImagePickerService Providers Tests', () {
    test('Providers can be read and provide correct instances', () {
      final container = ProviderContainer(
        overrides: [
          loggerProvider.overrideWithValue(mockTalker),
          appLockServiceProvider.overrideWith(FakeAppLockService.new),
        ],
      );
      addTearDown(container.dispose);

      check(container.read(imagePickerProvider)).isA<ImagePicker>();
      check(container.read(imageCropperProvider)).isA<ImageCropper>();
      check(
        container.read(imagePickerServiceProvider),
      ).isA<ImagePickerService>();
    });
  });
}
