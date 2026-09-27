// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [HomeWidgetDataSource] を提供するプロバイダー

@ProviderFor(homeWidgetDataSource)
final homeWidgetDataSourceProvider = HomeWidgetDataSourceProvider._();

/// [HomeWidgetDataSource] を提供するプロバイダー

final class HomeWidgetDataSourceProvider
    extends
        $FunctionalProvider<
          HomeWidgetDataSource,
          HomeWidgetDataSource,
          HomeWidgetDataSource
        >
    with $Provider<HomeWidgetDataSource> {
  /// [HomeWidgetDataSource] を提供するプロバイダー
  HomeWidgetDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetDataSourceHash();

  @$internal
  @override
  $ProviderElement<HomeWidgetDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HomeWidgetDataSource create(Ref ref) {
    return homeWidgetDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeWidgetDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeWidgetDataSource>(value),
    );
  }
}

String _$homeWidgetDataSourceHash() =>
    r'44455ba8e1ee8f7905f373b68664afa70387f85d';
