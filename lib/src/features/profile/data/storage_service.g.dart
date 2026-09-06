// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// FirebaseStorage を提供するプロバイダー

@ProviderFor(firebaseStorage)
final firebaseStorageProvider = FirebaseStorageProvider._();

/// FirebaseStorage を提供するプロバイダー

final class FirebaseStorageProvider
    extends
        $FunctionalProvider<FirebaseStorage, FirebaseStorage, FirebaseStorage>
    with $Provider<FirebaseStorage> {
  /// FirebaseStorage を提供するプロバイダー
  FirebaseStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseStorageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseStorageHash();

  @$internal
  @override
  $ProviderElement<FirebaseStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseStorage create(Ref ref) {
    return firebaseStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseStorage>(value),
    );
  }
}

String _$firebaseStorageHash() => r'47903c48019f7dfa1ba82fa0a905885442d69f6b';

/// StorageService を提供するプロバイダー

@ProviderFor(storageService)
final storageServiceProvider = StorageServiceProvider._();

/// StorageService を提供するプロバイダー

final class StorageServiceProvider
    extends $FunctionalProvider<StorageService, StorageService, StorageService>
    with $Provider<StorageService> {
  /// StorageService を提供するプロバイダー
  StorageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageServiceHash();

  @$internal
  @override
  $ProviderElement<StorageService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StorageService create(Ref ref) {
    return storageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageService>(value),
    );
  }
}

String _$storageServiceHash() => r'71b92796c94ede7218b70ea33374fef9475b9d87';
