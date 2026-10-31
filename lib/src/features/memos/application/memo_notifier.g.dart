// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 🔍 メモ一覧の検索・絞り込み・ソート条件を管理するプロバイダー

@ProviderFor(MemoFilterNotifier)
final memoFilterProvider = MemoFilterNotifierProvider._();

/// 🔍 メモ一覧の検索・絞り込み・ソート条件を管理するプロバイダー
final class MemoFilterNotifierProvider
    extends $NotifierProvider<MemoFilterNotifier, MemoFilterState> {
  /// 🔍 メモ一覧の検索・絞り込み・ソート条件を管理するプロバイダー
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
    r'ac275bede365dcb40aa1766f8da2915c549a17fc';

/// 🔍 メモ一覧の検索・絞り込み・ソート条件を管理するプロバイダー

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

/// メモ一覧のデータ（状態）を管理するためのクラス

@ProviderFor(MemoNotifier)
final memoProvider = MemoNotifierProvider._();

/// メモ一覧のデータ（状態）を管理するためのクラス
final class MemoNotifierProvider
    extends $StreamNotifierProvider<MemoNotifier, List<MemoModel>> {
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

String _$memoNotifierHash() => r'cc1861dd9c0937ec0fc63c0d2c588be8f859f6f3';

/// メモ一覧のデータ（状態）を管理するためのクラス

abstract class _$MemoNotifier extends $StreamNotifier<List<MemoModel>> {
  Stream<List<MemoModel>> build();
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
