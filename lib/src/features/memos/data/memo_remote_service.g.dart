// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_remote_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [MemoRemoteService] をアプリのどこからでも簡単に呼び出せるようにするためのプロバイダー

@ProviderFor(memoRemoteService)
final memoRemoteServiceProvider = MemoRemoteServiceProvider._();

/// [MemoRemoteService] をアプリのどこからでも簡単に呼び出せるようにするためのプロバイダー

final class MemoRemoteServiceProvider
    extends
        $FunctionalProvider<
          MemoRemoteService,
          MemoRemoteService,
          MemoRemoteService
        >
    with $Provider<MemoRemoteService> {
  /// [MemoRemoteService] をアプリのどこからでも簡単に呼び出せるようにするためのプロバイダー
  MemoRemoteServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoRemoteServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoRemoteServiceHash();

  @$internal
  @override
  $ProviderElement<MemoRemoteService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MemoRemoteService create(Ref ref) {
    return memoRemoteService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoRemoteService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoRemoteService>(value),
    );
  }
}

String _$memoRemoteServiceHash() => r'5680d4c83d8c3dc021d9eac52a73f0b317ba8c4d';
