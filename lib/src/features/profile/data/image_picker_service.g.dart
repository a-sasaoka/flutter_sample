// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_picker_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ImagePicker を提供するプロバイダー

@ProviderFor(imagePicker)
final imagePickerProvider = ImagePickerProvider._();

/// ImagePicker を提供するプロバイダー

final class ImagePickerProvider
    extends $FunctionalProvider<ImagePicker, ImagePicker, ImagePicker>
    with $Provider<ImagePicker> {
  /// ImagePicker を提供するプロバイダー
  ImagePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imagePickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imagePickerHash();

  @$internal
  @override
  $ProviderElement<ImagePicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImagePicker create(Ref ref) {
    return imagePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImagePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImagePicker>(value),
    );
  }
}

String _$imagePickerHash() => r'7740c09b2d6b395ce466f1b72b93b31db7bfd740';

/// ImageCropper を提供するプロバイダー

@ProviderFor(imageCropper)
final imageCropperProvider = ImageCropperProvider._();

/// ImageCropper を提供するプロバイダー

final class ImageCropperProvider
    extends $FunctionalProvider<ImageCropper, ImageCropper, ImageCropper>
    with $Provider<ImageCropper> {
  /// ImageCropper を提供するプロバイダー
  ImageCropperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageCropperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageCropperHash();

  @$internal
  @override
  $ProviderElement<ImageCropper> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImageCropper create(Ref ref) {
    return imageCropper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageCropper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageCropper>(value),
    );
  }
}

String _$imageCropperHash() => r'89f9dc30a8d31f70b56669c88590e1ca1608d325';

/// ImagePickerService を提供するプロバイダー

@ProviderFor(imagePickerService)
final imagePickerServiceProvider = ImagePickerServiceProvider._();

/// ImagePickerService を提供するプロバイダー

final class ImagePickerServiceProvider
    extends
        $FunctionalProvider<
          ImagePickerService,
          ImagePickerService,
          ImagePickerService
        >
    with $Provider<ImagePickerService> {
  /// ImagePickerService を提供するプロバイダー
  ImagePickerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imagePickerServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imagePickerServiceHash();

  @$internal
  @override
  $ProviderElement<ImagePickerService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImagePickerService create(Ref ref) {
    return imagePickerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImagePickerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImagePickerService>(value),
    );
  }
}

String _$imagePickerServiceHash() =>
    r'f7df5fae6ce4a16a9316ddc0646e1459631b510d';
