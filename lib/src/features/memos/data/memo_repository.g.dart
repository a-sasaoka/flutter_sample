// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

String _$memoRepositoryHash() => r'19e86ccef2d75712d52e370aaa9e16f818a5ff2d';
