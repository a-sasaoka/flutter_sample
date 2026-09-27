// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [SharePlus] インスタンスを提供するプロバイダー

@ProviderFor(sharePlus)
final sharePlusProvider = SharePlusProvider._();

/// [SharePlus] インスタンスを提供するプロバイダー

final class SharePlusProvider
    extends $FunctionalProvider<SharePlus, SharePlus, SharePlus>
    with $Provider<SharePlus> {
  /// [SharePlus] インスタンスを提供するプロバイダー
  SharePlusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharePlusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharePlusHash();

  @$internal
  @override
  $ProviderElement<SharePlus> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SharePlus create(Ref ref) {
    return sharePlus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharePlus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharePlus>(value),
    );
  }
}

String _$sharePlusHash() => r'3d9c219d4abc73f6669b26e3f462fc15f359ac8f';

/// [ShareService] を提供するプロバイダー

@ProviderFor(shareService)
final shareServiceProvider = ShareServiceProvider._();

/// [ShareService] を提供するプロバイダー

final class ShareServiceProvider
    extends $FunctionalProvider<ShareService, ShareService, ShareService>
    with $Provider<ShareService> {
  /// [ShareService] を提供するプロバイダー
  ShareServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareServiceHash();

  @$internal
  @override
  $ProviderElement<ShareService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShareService create(Ref ref) {
    return shareService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareService>(value),
    );
  }
}

String _$shareServiceHash() => r'f590abe403bf81e4de78102b4d4aa70da186dcad';
