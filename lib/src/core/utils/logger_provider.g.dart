// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logger_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loggerプロバイダ

@ProviderFor(logger)
const loggerProvider = LoggerProvider._();

/// Loggerプロバイダ

final class LoggerProvider extends $FunctionalProvider<Logger, Logger, Logger>
    with $Provider<Logger> {
  /// Loggerプロバイダ
  const LoggerProvider._()
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
  $ProviderElement<Logger> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Logger create(Ref ref) {
    return logger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Logger value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Logger>(value),
    );
  }
}

String _$loggerHash() => r'b97993adf60a48b7d9a98ec92699dbac26756c0f';
