import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'image_picker_service.g.dart';

/// 画像の取得元
enum AvatarPickSource {
  /// カメラで撮影
  camera,

  /// 写真ライブラリから選択
  gallery,
}

/// 権限が拒否されたことを表す例外
class AvatarPermissionDeniedException implements Exception {
  /// コンストラクタ
  const AvatarPermissionDeniedException({
    required this.permission,
    this.isPermanentlyDenied = false,
  });

  /// 拒否された権限
  final Permission permission;

  /// 設定画面でのみ許可可能な永久拒否状態かどうか
  final bool isPermanentlyDenied;

  @override
  String toString() =>
      'AvatarPermissionDeniedException: $permission '
      '(permanently: $isPermanentlyDenied)';
}

/// ImagePicker を提供するプロバイダー
@riverpod
ImagePicker imagePicker(Ref ref) => ImagePicker();

/// ImageCropper を提供するプロバイダー
@riverpod
ImageCropper imageCropper(Ref ref) => ImageCropper();

/// ImagePickerService を提供するプロバイダー
@riverpod
ImagePickerService imagePickerService(Ref ref) {
  return ImagePickerService(
    picker: ref.watch(imagePickerProvider),
    cropper: ref.watch(imageCropperProvider),
    talker: ref.watch(loggerProvider),
    appLockService: ref.watch(appLockServiceProvider.notifier),
  );
}

/// カメラ・写真アルバムからの画像取得、切り抜き、および権限管理を行うサービスクラス
class ImagePickerService {
  /// コンストラクタ
  const ImagePickerService({
    required this.picker,
    required this.cropper,
    required this.talker,
    this.appLockService,
  });

  /// 画像選択プラグイン
  final ImagePicker picker;

  /// 画像切り抜きプラグイン
  final ImageCropper cropper;

  /// ロガー
  final Talker talker;

  /// アプリロックサービス（外部画面表示時の誤ロック防止用）
  final AppLockService? appLockService;

  /// 必要な権限をチェック・リクエストする
  /// 拒否されている場合は [AvatarPermissionDeniedException] をスローする
  Future<void> checkAndRequestPermission(AvatarPickSource source) async {
    final permission = switch (source) {
      AvatarPickSource.camera => Permission.camera,
      AvatarPickSource.gallery => Permission.photos,
    };

    final status = await permission.status;
    if (status.isPermanentlyDenied) {
      talker.warning('Permission permanently denied: $permission');
      throw AvatarPermissionDeniedException(
        permission: permission,
        isPermanentlyDenied: true,
      );
    }

    if (!status.isGranted && !status.isLimited) {
      final result = await permission.request();
      if (result.isPermanentlyDenied) {
        talker.warning(
          'Permission permanently denied after request: $permission',
        );
        throw AvatarPermissionDeniedException(
          permission: permission,
          isPermanentlyDenied: true,
        );
      }
      if (!result.isGranted && !result.isLimited) {
        talker.warning('Permission denied: $permission');
        throw AvatarPermissionDeniedException(
          permission: permission,
        );
      }
    }
  }

  /// スマホの「設定」アプリを開く
  Future<bool> openSettings() async {
    talker.debug('Opening app settings...');
    return openAppSettings();
  }

  /// 画像を選択し、円形に切り抜いたファイルパスを返す
  /// ユーザーがキャンセルした場合は null を返す
  Future<String?> pickAndCropAvatar({
    required AvatarPickSource source,
    required String cropperTitle,
  }) async {
    final lockService = appLockService;
    if (lockService != null) {
      return lockService.runWithLockSuppression(
        () => _pickAndCropAvatarInternal(
          source: source,
          cropperTitle: cropperTitle,
        ),
      );
    }
    return _pickAndCropAvatarInternal(
      source: source,
      cropperTitle: cropperTitle,
    );
  }

  Future<String?> _pickAndCropAvatarInternal({
    required AvatarPickSource source,
    required String cropperTitle,
  }) async {
    await checkAndRequestPermission(source);

    final imageSource = switch (source) {
      AvatarPickSource.camera => ImageSource.camera,
      AvatarPickSource.gallery => ImageSource.gallery,
    };

    talker.debug('Picking image from: $imageSource');
    final pickedFile = await picker.pickImage(
      source: imageSource,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null) {
      talker.debug('Image picking was cancelled by user.');
      return null;
    }

    talker.debug('Image picked: ${pickedFile.path}. Cropping...');
    final croppedFile = await cropper.cropImage(
      sourcePath: pickedFile.path,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: cropperTitle,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
        IOSUiSettings(
          title: cropperTitle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
      ],
    );

    if (croppedFile == null) {
      talker.debug('Image cropping was cancelled by user.');
      return null;
    }

    talker.debug('Image cropped successfully: ${croppedFile.path}');
    return croppedFile.path;
  }
}
