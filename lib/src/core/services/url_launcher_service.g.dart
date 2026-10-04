// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'url_launcher_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [UrlLauncherService] を提供するプロバイダー

@ProviderFor(urlLauncherService)
final urlLauncherServiceProvider = UrlLauncherServiceProvider._();

/// [UrlLauncherService] を提供するプロバイダー

final class UrlLauncherServiceProvider
    extends
        $FunctionalProvider<
          UrlLauncherService,
          UrlLauncherService,
          UrlLauncherService
        >
    with $Provider<UrlLauncherService> {
  /// [UrlLauncherService] を提供するプロバイダー
  UrlLauncherServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'urlLauncherServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$urlLauncherServiceHash();

  @$internal
  @override
  $ProviderElement<UrlLauncherService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UrlLauncherService create(Ref ref) {
    return urlLauncherService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UrlLauncherService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UrlLauncherService>(value),
    );
  }
}

String _$urlLauncherServiceHash() =>
    r'5c65b6b49c378b3991fa38771688c0e84755d644';
