// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

String _$memoNotifierHash() => r'c91561e728f59e34c9a175a29f6a1220eff62747';

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
