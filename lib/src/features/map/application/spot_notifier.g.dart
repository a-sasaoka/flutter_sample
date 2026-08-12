// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spot_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 🗺️ スポット一覧を管理・更新する Notifier

@ProviderFor(SpotNotifier)
final spotProvider = SpotNotifierProvider._();

/// 🗺️ スポット一覧を管理・更新する Notifier
final class SpotNotifierProvider
    extends $AsyncNotifierProvider<SpotNotifier, List<MapSpot>> {
  /// 🗺️ スポット一覧を管理・更新する Notifier
  SpotNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spotProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spotNotifierHash();

  @$internal
  @override
  SpotNotifier create() => SpotNotifier();
}

String _$spotNotifierHash() => r'4cdac6027951a8761076828997fdbbc67765f0ce';

/// 🗺️ スポット一覧を管理・更新する Notifier

abstract class _$SpotNotifier extends $AsyncNotifier<List<MapSpot>> {
  FutureOr<List<MapSpot>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<MapSpot>>, List<MapSpot>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<MapSpot>>, List<MapSpot>>,
              AsyncValue<List<MapSpot>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
