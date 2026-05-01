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

String _$memoNotifierHash() => r'f1e0cdafb0aa292a8fe87b5727f583bcededb53f';

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
