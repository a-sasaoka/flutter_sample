// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 検索クエリ（キーワード）を管理するためのプロバイダー（状態管理）

@ProviderFor(MemoSearchQuery)
final memoSearchQueryProvider = MemoSearchQueryProvider._();

/// 検索クエリ（キーワード）を管理するためのプロバイダー（状態管理）
final class MemoSearchQueryProvider
    extends $NotifierProvider<MemoSearchQuery, String> {
  /// 検索クエリ（キーワード）を管理するためのプロバイダー（状態管理）
  MemoSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoSearchQueryHash();

  @$internal
  @override
  MemoSearchQuery create() => MemoSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$memoSearchQueryHash() => r'4ec4ce0c69361225f7636c83411e0410a88da9d2';

/// 検索クエリ（キーワード）を管理するためのプロバイダー（状態管理）

abstract class _$MemoSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 並び替え（ソート）ルールを管理するためのプロバイダー（状態管理）

@ProviderFor(MemoSortOrderState)
final memoSortOrderStateProvider = MemoSortOrderStateProvider._();

/// 並び替え（ソート）ルールを管理するためのプロバイダー（状態管理）
final class MemoSortOrderStateProvider
    extends $NotifierProvider<MemoSortOrderState, MemoSortOrder> {
  /// 並び替え（ソート）ルールを管理するためのプロバイダー（状態管理）
  MemoSortOrderStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoSortOrderStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoSortOrderStateHash();

  @$internal
  @override
  MemoSortOrderState create() => MemoSortOrderState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoSortOrder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoSortOrder>(value),
    );
  }
}

String _$memoSortOrderStateHash() =>
    r'a57e593affb471112f0d3ed5d63ea5fbc05fe514';

/// 並び替え（ソート）ルールを管理するためのプロバイダー（状態管理）

abstract class _$MemoSortOrderState extends $Notifier<MemoSortOrder> {
  MemoSortOrder build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MemoSortOrder, MemoSortOrder>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MemoSortOrder, MemoSortOrder>,
              MemoSortOrder,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// メモ一覧のデータ（状態）を管理するためのクラス

@ProviderFor(MemoNotifier)
final memoProvider = MemoNotifierProvider._();

/// メモ一覧のデータ（状態）を管理するためのクラス
final class MemoNotifierProvider
    extends $AsyncNotifierProvider<MemoNotifier, List<MemoModel>> {
  /// メモ一覧のデータ（状態）を管理するためのクラス
  MemoNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoNotifierHash();

  @$internal
  @override
  MemoNotifier create() => MemoNotifier();
}

String _$memoNotifierHash() => r'75bde6ad3223ec81567b7a5428b84b4fd15d870d';

/// メモ一覧のデータ（状態）を管理するためのクラス

abstract class _$MemoNotifier extends $AsyncNotifier<List<MemoModel>> {
  FutureOr<List<MemoModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<MemoModel>>, List<MemoModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<MemoModel>>, List<MemoModel>>,
              AsyncValue<List<MemoModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
