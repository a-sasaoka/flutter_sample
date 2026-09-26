// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submit_animation_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 送信ボタンのアニメーション状態を管理するNotifier

@ProviderFor(SubmitAnimationController)
final submitAnimationControllerProvider = SubmitAnimationControllerProvider._();

/// 送信ボタンのアニメーション状態を管理するNotifier
final class SubmitAnimationControllerProvider
    extends $NotifierProvider<SubmitAnimationController, SubmitStatus> {
  /// 送信ボタンのアニメーション状態を管理するNotifier
  SubmitAnimationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'submitAnimationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$submitAnimationControllerHash();

  @$internal
  @override
  SubmitAnimationController create() => SubmitAnimationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubmitStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubmitStatus>(value),
    );
  }
}

String _$submitAnimationControllerHash() =>
    r'd004f60f7a3a9592d5c7413ea234e9fea69dae3c';

/// 送信ボタンのアニメーション状態を管理するNotifier

abstract class _$SubmitAnimationController extends $Notifier<SubmitStatus> {
  SubmitStatus build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SubmitStatus, SubmitStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SubmitStatus, SubmitStatus>,
              SubmitStatus,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
