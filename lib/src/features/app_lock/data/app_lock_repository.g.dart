// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lock_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AppLockRepository を提供するプロバイダー

@ProviderFor(appLockRepository)
final appLockRepositoryProvider = AppLockRepositoryProvider._();

/// AppLockRepository を提供するプロバイダー

final class AppLockRepositoryProvider
    extends
        $FunctionalProvider<
          AppLockRepository,
          AppLockRepository,
          AppLockRepository
        >
    with $Provider<AppLockRepository> {
  /// AppLockRepository を提供するプロバイダー
  AppLockRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppLockRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppLockRepository create(Ref ref) {
    return appLockRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLockRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLockRepository>(value),
    );
  }
}

String _$appLockRepositoryHash() => r'403baaccc87100bde0aae9f49117697c49b7198a';
