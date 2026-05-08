// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// JSON から読み込んだ環境設定を提供するプロバイダー。

@ProviderFor(envConfig)
final envConfigProvider = EnvConfigProvider._();

/// JSON から読み込んだ環境設定を提供するプロバイダー。

final class EnvConfigProvider
    extends $FunctionalProvider<EnvConfigState, EnvConfigState, EnvConfigState>
    with $Provider<EnvConfigState> {
  /// JSON から読み込んだ環境設定を提供するプロバイダー。
  EnvConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'envConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$envConfigHash();

  @$internal
  @override
  $ProviderElement<EnvConfigState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EnvConfigState create(Ref ref) {
    return envConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EnvConfigState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EnvConfigState>(value),
    );
  }
}

String _$envConfigHash() => r'1a6c88531db0cbe5e4ad0ba0b480be65f762376b';
