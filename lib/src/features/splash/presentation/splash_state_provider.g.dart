// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 🌊 スプラッシュ画面の表示完了状態を管理するNotifierプロバイダー
///
/// アプリ起動時に最低表示時間（例：2秒）を満たしたかどうかを管理します。

@ProviderFor(SplashState)
final splashStateProvider = SplashStateProvider._();

/// 🌊 スプラッシュ画面の表示完了状態を管理するNotifierプロバイダー
///
/// アプリ起動時に最低表示時間（例：2秒）を満たしたかどうかを管理します。
final class SplashStateProvider extends $NotifierProvider<SplashState, bool> {
  /// 🌊 スプラッシュ画面の表示完了状態を管理するNotifierプロバイダー
  ///
  /// アプリ起動時に最低表示時間（例：2秒）を満たしたかどうかを管理します。
  SplashStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'splashStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$splashStateHash();

  @$internal
  @override
  SplashState create() => SplashState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$splashStateHash() => r'365421d366397fc98d5ed8143e297cbcd5e20202';

/// 🌊 スプラッシュ画面の表示完了状態を管理するNotifierプロバイダー
///
/// アプリ起動時に最低表示時間（例：2秒）を満たしたかどうかを管理します。

abstract class _$SplashState extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
