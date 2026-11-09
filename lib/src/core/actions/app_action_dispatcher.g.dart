// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_action_dispatcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 共通ディスパッチャーを提供するプロバイダー
///
/// Core層が個別Featureに依存しないよう、デフォルトは未設定（UnimplementedError）とし、
/// アプリ起動時（`main.dart`）やテスト時に具体的な実装でオーバーライドされます。

@ProviderFor(appActionDispatcher)
final appActionDispatcherProvider = AppActionDispatcherProvider._();

/// 共通ディスパッチャーを提供するプロバイダー
///
/// Core層が個別Featureに依存しないよう、デフォルトは未設定（UnimplementedError）とし、
/// アプリ起動時（`main.dart`）やテスト時に具体的な実装でオーバーライドされます。

final class AppActionDispatcherProvider
    extends
        $FunctionalProvider<
          AppActionDispatcher,
          AppActionDispatcher,
          AppActionDispatcher
        >
    with $Provider<AppActionDispatcher> {
  /// 共通ディスパッチャーを提供するプロバイダー
  ///
  /// Core層が個別Featureに依存しないよう、デフォルトは未設定（UnimplementedError）とし、
  /// アプリ起動時（`main.dart`）やテスト時に具体的な実装でオーバーライドされます。
  AppActionDispatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appActionDispatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appActionDispatcherHash();

  @$internal
  @override
  $ProviderElement<AppActionDispatcher> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppActionDispatcher create(Ref ref) {
    return appActionDispatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppActionDispatcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppActionDispatcher>(value),
    );
  }
}

String _$appActionDispatcherHash() =>
    r'64acd7435e1fc17cc6f3858e1e8ef5f49a6da5f3';
