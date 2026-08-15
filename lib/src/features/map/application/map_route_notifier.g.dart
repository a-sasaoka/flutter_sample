// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_route_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ルート検索および案内状態を管理する Notifier

@ProviderFor(MapRouteNotifier)
final mapRouteProvider = MapRouteNotifierProvider._();

/// ルート検索および案内状態を管理する Notifier
final class MapRouteNotifierProvider
    extends $NotifierProvider<MapRouteNotifier, MapRouteState> {
  /// ルート検索および案内状態を管理する Notifier
  MapRouteNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapRouteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapRouteNotifierHash();

  @$internal
  @override
  MapRouteNotifier create() => MapRouteNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapRouteState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapRouteState>(value),
    );
  }
}

String _$mapRouteNotifierHash() => r'2da971d14236d254814a8e6b2eccd60df2ce3d3d';

/// ルート検索および案内状態を管理する Notifier

abstract class _$MapRouteNotifier extends $Notifier<MapRouteState> {
  MapRouteState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MapRouteState, MapRouteState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MapRouteState, MapRouteState>,
              MapRouteState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
