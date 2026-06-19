// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secure_storage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SecureStorageのデータを非同期で監視・操作するNotifier

@ProviderFor(SecureStorageItems)
final secureStorageItemsProvider = SecureStorageItemsProvider._();

/// SecureStorageのデータを非同期で監視・操作するNotifier
final class SecureStorageItemsProvider
    extends $AsyncNotifierProvider<SecureStorageItems, Map<String, String>> {
  /// SecureStorageのデータを非同期で監視・操作するNotifier
  SecureStorageItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secureStorageItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secureStorageItemsHash();

  @$internal
  @override
  SecureStorageItems create() => SecureStorageItems();
}

String _$secureStorageItemsHash() =>
    r'8cfaa0602affd4084bb2dedb1e680937f480a5dd';

/// SecureStorageのデータを非同期で監視・操作するNotifier

abstract class _$SecureStorageItems
    extends $AsyncNotifier<Map<String, String>> {
  FutureOr<Map<String, String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Map<String, String>>, Map<String, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Map<String, String>>, Map<String, String>>,
              AsyncValue<Map<String, String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
