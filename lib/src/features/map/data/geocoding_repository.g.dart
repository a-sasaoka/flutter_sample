// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geocoding_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// GeocodingRepository のプロバイダー定義（単なるDartクラスのため関数プロバイダとして定義）

@ProviderFor(geocodingRepository)
final geocodingRepositoryProvider = GeocodingRepositoryProvider._();

/// GeocodingRepository のプロバイダー定義（単なるDartクラスのため関数プロバイダとして定義）

final class GeocodingRepositoryProvider
    extends
        $FunctionalProvider<
          GeocodingRepository,
          GeocodingRepository,
          GeocodingRepository
        >
    with $Provider<GeocodingRepository> {
  /// GeocodingRepository のプロバイダー定義（単なるDartクラスのため関数プロバイダとして定義）
  GeocodingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geocodingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geocodingRepositoryHash();

  @$internal
  @override
  $ProviderElement<GeocodingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GeocodingRepository create(Ref ref) {
    return geocodingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeocodingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeocodingRepository>(value),
    );
  }
}

String _$geocodingRepositoryHash() =>
    r'fd9b90d68f6df174629233718ad74de817e9b249';
