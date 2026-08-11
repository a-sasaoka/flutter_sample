// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_search_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 🗺️ 地図検索状態を管理・更新する Notifier

@ProviderFor(MapSearchNotifier)
final mapSearchProvider = MapSearchNotifierProvider._();

/// 🗺️ 地図検索状態を管理・更新する Notifier
final class MapSearchNotifierProvider
    extends $NotifierProvider<MapSearchNotifier, MapSearchState> {
  /// 🗺️ 地図検索状態を管理・更新する Notifier
  MapSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapSearchNotifierHash();

  @$internal
  @override
  MapSearchNotifier create() => MapSearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapSearchState>(value),
    );
  }
}

String _$mapSearchNotifierHash() => r'138d92bea38aa0e5bb3a937c192f2975fba064cb';

/// 🗺️ 地図検索状態を管理・更新する Notifier

abstract class _$MapSearchNotifier extends $Notifier<MapSearchState> {
  MapSearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MapSearchState, MapSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MapSearchState, MapSearchState>,
              MapSearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
