// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transit_launcher_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [TransitLauncherService] を提供する Riverpod プロバイダー

@ProviderFor(transitLauncherService)
final transitLauncherServiceProvider = TransitLauncherServiceProvider._();

/// [TransitLauncherService] を提供する Riverpod プロバイダー

final class TransitLauncherServiceProvider
    extends
        $FunctionalProvider<
          TransitLauncherService,
          TransitLauncherService,
          TransitLauncherService
        >
    with $Provider<TransitLauncherService> {
  /// [TransitLauncherService] を提供する Riverpod プロバイダー
  TransitLauncherServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transitLauncherServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transitLauncherServiceHash();

  @$internal
  @override
  $ProviderElement<TransitLauncherService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransitLauncherService create(Ref ref) {
    return transitLauncherService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransitLauncherService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransitLauncherService>(value),
    );
  }
}

String _$transitLauncherServiceHash() =>
    r'6c3695e5726b1958e599e544583cb393254699ed';
