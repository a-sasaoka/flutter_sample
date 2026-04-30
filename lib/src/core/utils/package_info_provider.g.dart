// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// アプリのパッケージ情報を取得するプロバイダ

@ProviderFor(packageInfo)
final packageInfoProvider = PackageInfoProvider._();

/// アプリのパッケージ情報を取得するプロバイダ

final class PackageInfoProvider
    extends $FunctionalProvider<PackageInfo, PackageInfo, PackageInfo>
    with $Provider<PackageInfo> {
  /// アプリのパッケージ情報を取得するプロバイダ
  PackageInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageInfoHash();

  @$internal
  @override
  $ProviderElement<PackageInfo> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PackageInfo create(Ref ref) {
    return packageInfo(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PackageInfo value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PackageInfo>(value),
    );
  }
}

String _$packageInfoHash() => r'da732cea6b06598516daa4e2625833d07d940182';
