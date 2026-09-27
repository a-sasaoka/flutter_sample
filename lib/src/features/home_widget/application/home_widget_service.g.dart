// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [HomeWidgetService] を提供するプロバイダー

@ProviderFor(homeWidgetService)
final homeWidgetServiceProvider = HomeWidgetServiceProvider._();

/// [HomeWidgetService] を提供するプロバイダー

final class HomeWidgetServiceProvider
    extends
        $FunctionalProvider<
          HomeWidgetService,
          HomeWidgetService,
          HomeWidgetService
        >
    with $Provider<HomeWidgetService> {
  /// [HomeWidgetService] を提供するプロバイダー
  HomeWidgetServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetServiceHash();

  @$internal
  @override
  $ProviderElement<HomeWidgetService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HomeWidgetService create(Ref ref) {
    return homeWidgetService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeWidgetService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeWidgetService>(value),
    );
  }
}

String _$homeWidgetServiceHash() => r'20833bbf5ea4192057dfdf6db2d8fe38d9d188d2';
