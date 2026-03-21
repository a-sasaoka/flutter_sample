// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_request_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// FirebaseRemoteConfigのインスタンスを提供するプロバイダ

@ProviderFor(firebaseRemoteConfig)
const firebaseRemoteConfigProvider = FirebaseRemoteConfigProvider._();

/// FirebaseRemoteConfigのインスタンスを提供するプロバイダ

final class FirebaseRemoteConfigProvider
    extends
        $FunctionalProvider<
          FirebaseRemoteConfig,
          FirebaseRemoteConfig,
          FirebaseRemoteConfig
        >
    with $Provider<FirebaseRemoteConfig> {
  /// FirebaseRemoteConfigのインスタンスを提供するプロバイダ
  const FirebaseRemoteConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseRemoteConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseRemoteConfigHash();

  @$internal
  @override
  $ProviderElement<FirebaseRemoteConfig> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseRemoteConfig create(Ref ref) {
    return firebaseRemoteConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseRemoteConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseRemoteConfig>(value),
    );
  }
}

String _$firebaseRemoteConfigHash() =>
    r'b77ccb5a415dded5f97912f191756d9103cc4faf';

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
    r'7bce677d9b1cfd4c3e78c683440b523f16a9c200';

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
