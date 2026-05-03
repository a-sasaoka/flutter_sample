// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chart_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// グラフデータの状態を管理するNotifier

@ProviderFor(ChartNotifier)
final chartProvider = ChartNotifierProvider._();

/// グラフデータの状態を管理するNotifier
final class ChartNotifierProvider
    extends $NotifierProvider<ChartNotifier, ChartState> {
  /// グラフデータの状態を管理するNotifier
  ChartNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chartProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chartNotifierHash();

  @$internal
  @override
  ChartNotifier create() => ChartNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChartState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChartState>(value),
    );
  }
}

String _$chartNotifierHash() => r'80d5d692ec4225ef47a5e082992188d670918215';

/// グラフデータの状態を管理するNotifier

abstract class _$ChartNotifier extends $Notifier<ChartState> {
  ChartState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChartState, ChartState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChartState, ChartState>,
              ChartState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
