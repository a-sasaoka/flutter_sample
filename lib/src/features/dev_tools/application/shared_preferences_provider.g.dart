// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SharedPreferencesのデータを非同期で監視・操作するNotifier

@ProviderFor(SharedPreferencesItems)
final sharedPreferencesItemsProvider = SharedPreferencesItemsProvider._();

/// SharedPreferencesのデータを非同期で監視・操作するNotifier
final class SharedPreferencesItemsProvider
    extends
        $AsyncNotifierProvider<SharedPreferencesItems, Map<String, Object?>> {
  /// SharedPreferencesのデータを非同期で監視・操作するNotifier
  SharedPreferencesItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesItemsHash();

  @$internal
  @override
  SharedPreferencesItems create() => SharedPreferencesItems();
}

String _$sharedPreferencesItemsHash() =>
    r'be44168b137edeba37e717e9c43d42e7459737b0';

/// SharedPreferencesのデータを非同期で監視・操作するNotifier

abstract class _$SharedPreferencesItems
    extends $AsyncNotifier<Map<String, Object?>> {
  FutureOr<Map<String, Object?>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Map<String, Object?>>, Map<String, Object?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, Object?>>,
                Map<String, Object?>
              >,
              AsyncValue<Map<String, Object?>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
