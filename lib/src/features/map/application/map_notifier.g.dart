// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 🗺️ 地図画面のカメラ・位置情報取得状態を管理する Notifier

@ProviderFor(MapNotifier)
final mapProvider = MapNotifierProvider._();

/// 🗺️ 地図画面のカメラ・位置情報取得状態を管理する Notifier
final class MapNotifierProvider
    extends $NotifierProvider<MapNotifier, LocationState> {
  /// 🗺️ 地図画面のカメラ・位置情報取得状態を管理する Notifier
  MapNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapNotifierHash();

  @$internal
  @override
  MapNotifier create() => MapNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationState>(value),
    );
  }
}

String _$mapNotifierHash() => r'9206997e38559f8f32a256d6a9aec11339cbe6f6';

/// 🗺️ 地図画面のカメラ・位置情報取得状態を管理する Notifier

abstract class _$MapNotifier extends $Notifier<LocationState> {
  LocationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LocationState, LocationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocationState, LocationState>,
              LocationState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
