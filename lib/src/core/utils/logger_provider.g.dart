// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logger_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 統合ロギングプロバイダ (Talker)

@ProviderFor(logger)
final loggerProvider = LoggerProvider._();

/// 統合ロギングプロバイダ (Talker)

final class LoggerProvider extends $FunctionalProvider<Talker, Talker, Talker>
    with $Provider<Talker> {
  /// 統合ロギングプロバイダ (Talker)
  LoggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loggerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loggerHash();

  @$internal
  @override
  $ProviderElement<Talker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Talker create(Ref ref) {
    return logger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Talker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Talker>(value),
    );
  }
}

String _$loggerHash() => r'eeaf4eb2e598ffd98694ea1f326da6dc8e9425fa';
