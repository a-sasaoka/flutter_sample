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

/// 現在認証中のユーザーIDを常に最新値として取得する関数プロバイダー
///
/// [memoRepositoryProvider] が破棄・再生成された後も、キュー内の待機タスクが
/// 破棄済み Ref を参照せずに最新の認証ユーザーIDを参照できるよう keepAlive にしています。

@ProviderFor(memoAuthUserIdReader)
final memoAuthUserIdReaderProvider = MemoAuthUserIdReaderProvider._();

/// 現在認証中のユーザーIDを常に最新値として取得する関数プロバイダー
///
/// [memoRepositoryProvider] が破棄・再生成された後も、キュー内の待機タスクが
/// 破棄済み Ref を参照せずに最新の認証ユーザーIDを参照できるよう keepAlive にしています。

final class MemoAuthUserIdReaderProvider
    extends
        $FunctionalProvider<
          String? Function(),
          String? Function(),
          String? Function()
        >
    with $Provider<String? Function()> {
  /// 現在認証中のユーザーIDを常に最新値として取得する関数プロバイダー
  ///
  /// [memoRepositoryProvider] が破棄・再生成された後も、キュー内の待機タスクが
  /// 破棄済み Ref を参照せずに最新の認証ユーザーIDを参照できるよう keepAlive にしています。
  MemoAuthUserIdReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoAuthUserIdReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoAuthUserIdReaderHash();

  @$internal
  @override
  $ProviderElement<String? Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  String? Function() create(Ref ref) {
    return memoAuthUserIdReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String? Function()>(value),
    );
  }
}

String _$memoAuthUserIdReaderHash() =>
    r'a887f43b82758e84a3550dcc01c5fdb4000bd813';

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

String _$memoRepositoryHash() => r'e599fa364b6443285338a01d5d53763125a6ee65';
