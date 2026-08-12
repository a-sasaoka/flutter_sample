// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spot_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SpotRepository の Provider

@ProviderFor(spotRepository)
final spotRepositoryProvider = SpotRepositoryProvider._();

/// SpotRepository の Provider

final class SpotRepositoryProvider
    extends $FunctionalProvider<SpotRepository, SpotRepository, SpotRepository>
    with $Provider<SpotRepository> {
  /// SpotRepository の Provider
  SpotRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spotRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spotRepositoryHash();

  @$internal
  @override
  $ProviderElement<SpotRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SpotRepository create(Ref ref) {
    return spotRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpotRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpotRepository>(value),
    );
  }
}

String _$spotRepositoryHash() => r'15ccd99cf7c9a7c6c4f8746c8a90fea87d7f7288';
