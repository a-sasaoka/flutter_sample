// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_crashlytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Firebase Crashlytics のインスタンスを提供するプロバイダー

@ProviderFor(firebaseCrashlytics)
final firebaseCrashlyticsProvider = FirebaseCrashlyticsProvider._();

/// Firebase Crashlytics のインスタンスを提供するプロバイダー

final class FirebaseCrashlyticsProvider
    extends
        $FunctionalProvider<
          FirebaseCrashlytics,
          FirebaseCrashlytics,
          FirebaseCrashlytics
        >
    with $Provider<FirebaseCrashlytics> {
  /// Firebase Crashlytics のインスタンスを提供するプロバイダー
  FirebaseCrashlyticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseCrashlyticsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseCrashlyticsHash();

  @$internal
  @override
  $ProviderElement<FirebaseCrashlytics> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseCrashlytics create(Ref ref) {
    return firebaseCrashlytics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseCrashlytics value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseCrashlytics>(value),
    );
  }
}

String _$firebaseCrashlyticsHash() =>
    r'79a26a071cd758fda3751491a257d58e01a258ec';
