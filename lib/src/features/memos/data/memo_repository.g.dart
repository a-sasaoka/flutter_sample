// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [MemoSyncQueue] をアプリ（ProviderContainer）全体で共有するプロバイダー

@ProviderFor(memoSyncQueue)
final memoSyncQueueProvider = MemoSyncQueueProvider._();

/// [MemoSyncQueue] をアプリ（ProviderContainer）全体で共有するプロバイダー

final class MemoSyncQueueProvider
    extends $FunctionalProvider<MemoSyncQueue, MemoSyncQueue, MemoSyncQueue>
    with $Provider<MemoSyncQueue> {
  /// [MemoSyncQueue] をアプリ（ProviderContainer）全体で共有するプロバイダー
  MemoSyncQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoSyncQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoSyncQueueHash();

  @$internal
  @override
  $ProviderElement<MemoSyncQueue> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MemoSyncQueue create(Ref ref) {
    return memoSyncQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoSyncQueue value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoSyncQueue>(value),
    );
  }
}

String _$memoSyncQueueHash() => r'f9946d29f60d53874ae08523922d8823d10e77ac';

/// アプリ全体で[MemoRepository]を使えるようにするためのプロバイダー

@ProviderFor(memoRepository)
final memoRepositoryProvider = MemoRepositoryProvider._();

/// アプリ全体で[MemoRepository]を使えるようにするためのプロバイダー

final class MemoRepositoryProvider
    extends $FunctionalProvider<MemoRepository, MemoRepository, MemoRepository>
    with $Provider<MemoRepository> {
  /// アプリ全体で[MemoRepository]を使えるようにするためのプロバイダー
  MemoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoRepositoryHash();

  @$internal
  @override
  $ProviderElement<MemoRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MemoRepository create(Ref ref) {
    return memoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoRepository>(value),
    );
  }
}

String _$memoRepositoryHash() => r'36d11287952287401c23c26b0c7f39d42c27392c';
