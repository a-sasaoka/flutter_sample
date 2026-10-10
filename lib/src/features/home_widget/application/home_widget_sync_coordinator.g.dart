// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_sync_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// メモ一覧のデータ変更をリアクティブに検知し、ホーム画面ウィジェットへ自動同期するコーディネーター

@ProviderFor(HomeWidgetSyncCoordinator)
final homeWidgetSyncCoordinatorProvider = HomeWidgetSyncCoordinatorProvider._();

/// メモ一覧のデータ変更をリアクティブに検知し、ホーム画面ウィジェットへ自動同期するコーディネーター
final class HomeWidgetSyncCoordinatorProvider
    extends $NotifierProvider<HomeWidgetSyncCoordinator, void> {
  /// メモ一覧のデータ変更をリアクティブに検知し、ホーム画面ウィジェットへ自動同期するコーディネーター
  HomeWidgetSyncCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetSyncCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetSyncCoordinatorHash();

  @$internal
  @override
  HomeWidgetSyncCoordinator create() => HomeWidgetSyncCoordinator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$homeWidgetSyncCoordinatorHash() =>
    r'9ee27daae5918cfaeaff45e1b454b743586d40f1';

/// メモ一覧のデータ変更をリアクティブに検知し、ホーム画面ウィジェットへ自動同期するコーディネーター

abstract class _$HomeWidgetSyncCoordinator extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
