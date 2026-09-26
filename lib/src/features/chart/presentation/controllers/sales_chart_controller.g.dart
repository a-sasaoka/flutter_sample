// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_chart_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 🛒 売上推移グラフの状態管理コントローラー

@ProviderFor(SalesChartController)
final salesChartControllerProvider = SalesChartControllerProvider._();

/// 🛒 売上推移グラフの状態管理コントローラー
final class SalesChartControllerProvider
    extends $NotifierProvider<SalesChartController, SalesChartState> {
  /// 🛒 売上推移グラフの状態管理コントローラー
  SalesChartControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salesChartControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salesChartControllerHash();

  @$internal
  @override
  SalesChartController create() => SalesChartController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SalesChartState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SalesChartState>(value),
    );
  }
}

String _$salesChartControllerHash() =>
    r'8536fb8e3ed61bd309fc1da5a0c4d534a698148a';

/// 🛒 売上推移グラフの状態管理コントローラー

abstract class _$SalesChartController extends $Notifier<SalesChartState> {
  SalesChartState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SalesChartState, SalesChartState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SalesChartState, SalesChartState>,
              SalesChartState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
