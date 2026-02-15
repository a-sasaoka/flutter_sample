// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_request_provider.dart.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// RemoteConfigからアップデート情報を取得するコントローラ

@ProviderFor(UpdateRequestController)
const updateRequestControllerProvider = UpdateRequestControllerProvider._();

/// RemoteConfigからアップデート情報を取得するコントローラ
final class UpdateRequestControllerProvider
    extends $AsyncNotifierProvider<UpdateRequestController, UpdateRequestType> {
  /// RemoteConfigからアップデート情報を取得するコントローラ
  const UpdateRequestControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateRequestControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateRequestControllerHash();

  @$internal
  @override
  UpdateRequestController create() => UpdateRequestController();
}

String _$updateRequestControllerHash() =>
    r'cb1322445e18dc86adb56fedad9365102541851f';

/// RemoteConfigからアップデート情報を取得するコントローラ

abstract class _$UpdateRequestController
    extends $AsyncNotifier<UpdateRequestType> {
  FutureOr<UpdateRequestType> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<UpdateRequestType>, UpdateRequestType>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UpdateRequestType>, UpdateRequestType>,
              AsyncValue<UpdateRequestType>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// アップデート情報のキャンセル有無を管理するコントローラ

@ProviderFor(CancelController)
const cancelControllerProvider = CancelControllerProvider._();

/// アップデート情報のキャンセル有無を管理するコントローラ
final class CancelControllerProvider
    extends $NotifierProvider<CancelController, bool> {
  /// アップデート情報のキャンセル有無を管理するコントローラ
  const CancelControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cancelControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cancelControllerHash();

  @$internal
  @override
  CancelController create() => CancelController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$cancelControllerHash() => r'09595f17e82ae7f436cf948772fdb389390079d1';

/// アップデート情報のキャンセル有無を管理するコントローラ

abstract class _$CancelController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
