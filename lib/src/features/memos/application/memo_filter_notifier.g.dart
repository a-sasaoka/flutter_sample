// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_filter_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// メモの検索・絞り込み・ソート状態を一元管理する Notifier

@ProviderFor(MemoFilterNotifier)
final memoFilterProvider = MemoFilterNotifierProvider._();

/// メモの検索・絞り込み・ソート状態を一元管理する Notifier
final class MemoFilterNotifierProvider
    extends $NotifierProvider<MemoFilterNotifier, MemoFilterState> {
  /// メモの検索・絞り込み・ソート状態を一元管理する Notifier
  MemoFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoFilterNotifierHash();

  @$internal
  @override
  MemoFilterNotifier create() => MemoFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoFilterState>(value),
    );
  }
}

String _$memoFilterNotifierHash() =>
    r'54686b4c906ffc23ee79c2e8ae061a66d6e68f80';

/// メモの検索・絞り込み・ソート状態を一元管理する Notifier

abstract class _$MemoFilterNotifier extends $Notifier<MemoFilterState> {
  MemoFilterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MemoFilterState, MemoFilterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MemoFilterState, MemoFilterState>,
              MemoFilterState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 検索クエリ（キーワード）を管理するためのプロバイダー（後方互換性用）

@ProviderFor(MemoSearchQuery)
final memoSearchQueryProvider = MemoSearchQueryProvider._();

/// 検索クエリ（キーワード）を管理するためのプロバイダー（後方互換性用）
final class MemoSearchQueryProvider
    extends $NotifierProvider<MemoSearchQuery, String> {
  /// 検索クエリ（キーワード）を管理するためのプロバイダー（後方互換性用）
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

String _$memoSearchQueryHash() => r'bad3a33dd7c1422b8794956e77ec5667ee142ffe';

/// 検索クエリ（キーワード）を管理するためのプロバイダー（後方互換性用）

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

/// 並び替え（ソート）ルールを管理するためのプロバイダー（後方互換性用）

@ProviderFor(MemoSortOrderState)
final memoSortOrderStateProvider = MemoSortOrderStateProvider._();

/// 並び替え（ソート）ルールを管理するためのプロバイダー（後方互換性用）
final class MemoSortOrderStateProvider
    extends $NotifierProvider<MemoSortOrderState, MemoSortOrder> {
  /// 並び替え（ソート）ルールを管理するためのプロバイダー（後方互換性用）
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
    r'99f49b0efe7b90fab653f9bb48cd2b75efc74388';

/// 並び替え（ソート）ルールを管理するためのプロバイダー（後方互換性用）

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
