// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rebuild_demo_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 再ビルド検証デモの状態を管理するNotifier

@ProviderFor(RebuildDemoNotifier)
final rebuildDemoProvider = RebuildDemoNotifierProvider._();

/// 再ビルド検証デモの状態を管理するNotifier
final class RebuildDemoNotifierProvider
    extends $NotifierProvider<RebuildDemoNotifier, RebuildDemoState> {
  /// 再ビルド検証デモの状態を管理するNotifier
  RebuildDemoNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rebuildDemoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rebuildDemoNotifierHash();

  @$internal
  @override
  RebuildDemoNotifier create() => RebuildDemoNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RebuildDemoState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RebuildDemoState>(value),
    );
  }
}

String _$rebuildDemoNotifierHash() =>
    r'1968d311b471377629a232f10ba0904a43b00b36';

/// 再ビルド検証デモの状態を管理するNotifier

abstract class _$RebuildDemoNotifier extends $Notifier<RebuildDemoState> {
  RebuildDemoState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RebuildDemoState, RebuildDemoState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RebuildDemoState, RebuildDemoState>,
              RebuildDemoState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
