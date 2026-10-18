// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_search_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [WebSearchService] を提供するプロバイダー

@ProviderFor(webSearchService)
final webSearchServiceProvider = WebSearchServiceProvider._();

/// [WebSearchService] を提供するプロバイダー

final class WebSearchServiceProvider
    extends
        $FunctionalProvider<
          WebSearchService,
          WebSearchService,
          WebSearchService
        >
    with $Provider<WebSearchService> {
  /// [WebSearchService] を提供するプロバイダー
  WebSearchServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webSearchServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webSearchServiceHash();

  @$internal
  @override
  $ProviderElement<WebSearchService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WebSearchService create(Ref ref) {
    return webSearchService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebSearchService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebSearchService>(value),
    );
  }
}

String _$webSearchServiceHash() => r'2f3df0f17c6ab926a7cfea1878a3f864f30e0f2a';
